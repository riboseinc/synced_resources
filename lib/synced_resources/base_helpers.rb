# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  module BaseHelpers

    protected

    # Wrap Rails's #respond_to with our own formatting routines for JSON &
    # XML responses.
    #
    # == Parameters
    # +arguments+  - a singular resource OR an enumerable collection of it
    #       and/or - a hash consisting of key-value pairs typically
    #                found in Controllers' `params' hash
    # +&blk+       - optional block for overriding responses
    #
    # == Options
    #
    # The primary key name can be passed in via 'options[:primary_key]'.
    # By default, it assumes the resource's primary key name is :id.
    #
    # With 'indices', can optionally specify whether to return the index map.
    #
    # It allows only specifying options
    #
    # == Examples
    #
    # def create
    #   super do |s, f|
    #     (respond_with_resources(resource, :view => :zoom, :x => :y) do |succ, fail, result|
    #       fail.xml { ... result... }
    #     end).(s, f)
    #   end
    # end
    #
    # def index
    #   super &respond_with_resources(do_something_to(collection))
    # end
    #
    # def destroy
    #   super &respond_with_resources(:view => :my_serialization_view)
    # end
    #
    def respond_with_resources(*arguments, &blk)
      object_or_objects, options = extract_parameters arguments

      results = compose_results_from_options object_or_objects, options

      # The default implementations for JSON & XML below will be overridden by
      # any block provided here by virtue of precedence.
      #
      respond_with_resources_sf results, options[:action], options[:view], &blk
    end

    def _total_entries(objects)
      objects.count
    end

    # convenience method
    def extract_parameters(arguments)
      case arguments.length
      when 0 then       [ resource, {} ]
      when 1 then
        case a = arguments[0]
        when Hash then  [ resource, a  ]
        else            [ a       , {} ]
        end
      else # 2
        arguments
      end
    end
    private :extract_parameters

    # a helper method for #respond_with_resources
    #
    # +view_options+ is an array of Symbols, e.g., [:with_history,
    # :with_individual].
    #
    def respond_with_resources_sf(results, action_options, view_options = (DEFAULT_VIEW_OPTIONS rescue []), &blk)

      option_hash = { view: view_options }

      # lambda {|*format_succ_fail|  # <-- does not work
      lambda { |success, failure = nil|

        # We reload to fix this : update readonly attribute -> it returns the
        # "updated" object (object in database is not changed), but we expect
        # to receive the correct (unchanged) object in database
        #
        # Force it to reload to fix the bug ...
        #
        # XXX: don't know why resource.reload unless action_options.to_s == 'destroy'
        # would also fail in index (test spec) ... the object should exist!
        resource.reload if action_options.to_s == "update"

        case [success, failure].compact.length

        when 0 then
          raise "omgwtfbbq unpossible!"

        when 1 then #  "Failure is not an option."
          format = success
          yield format, results if blk

          format.json { render json: results.to_json(option_hash)                    }
          format.xml  { render xml: results. to_xml(option_hash.merge(root: "data")) }

        else # when 2 then "success"-"failure"

          yield success, failure, results if blk

          # TODO: any better way to prevent serialization of destroyed object
          success.json do
            render json: (action_options.to_s == "destroy" ? {} : results)
              .to_json(option_hash)
          end
          success.xml do
            render xml: (action_options.to_s == "destroy" ? {} : results)
              .to_xml(option_hash.merge(root: "data"))
          end

          failure.json { render json: resource.errors, status: :unprocessable_entity }
          failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
        end
      }
    end
    private :respond_with_resources_sf

    def _compose_requested_at(results, objects, _is_collection, _options = {})
      results[:requested_at] = self.class.time_to_synced_at

      [results, objects]
    end
    private :_compose_requested_at

    # NOTE: not enabling rejected_ids for now as it doesn't work properly
    # TODO: think of a way to make it work
    def _compose_rejected_ids(results, objects, _is_collection, options = {})
      synced_at_map = SyncedResources.sync_string_decoder.call(
        options[:s],
        self.class.base_time,
      )

      klass = objects.klass
      primary_key_name = klass.primary_key.to_sym

      re_objects = objects
      if klass.column_names.include? "updated_at"
        # Needed?
        # primary_key = objects.first[primary_key_name]
        # klass.column_types[primary_key_name].type

        # No restrictions on never-synced IDs
        synced_ids = synced_at_map.keys

        first_arel = klass.arel_table[primary_key_name].not_in(synced_ids)

        selected_relations = synced_at_map.map do |object_id, synced_at|
          klass.arel_table[primary_key_name].eq(object_id).and(
            klass.arel_table[:updated_at].gt(self.class.synced_at_to_time(synced_at).to_s(:db))
          )
        end

        # Reject previously synced IDs that have not been updated
        selected = selected_relations.reduce(first_arel) do |acc, rel|
          acc.or(rel)
        end

        original_ids = objects.pluck(primary_key_name)

        re_objects = klass
                     .where(klass.arel_table[primary_key_name].in(original_ids))
                     .where(selected)

      end

      # # assert indices set contains re_objects
      # difference = Set.new(re_objects.pluck(primary_key_name)) -
      #              Set.new(results[:indices].values)

      [results, re_objects]
    end
    private :_compose_rejected_ids

    def _compose_range_total(results, objects, _is_collection, _options = {})
      results[:total] = _total_entries objects
      objects = objects.view_order_range(view)

      [results, objects]
    end
    private :_compose_range_total

    def _compose_indices(results, objects, _is_collection, _options = {})

      klass = objects.klass
      primary_key_name = klass.primary_key.to_sym

      # collection with `s=':  compose the `:indices' hash

      offset = view.start.to_i # => nil.to_i == 0, the desired default

      # XXX: #pluck would sometimes return duplicate ids, if e.g. OUTER JOINS are
      # used somewhere in the association chain.
      #
      # all_ids = objects.pluck(primary_key_name)
      # all_ids = objects
      #           .except(:select)
      #           .select(primary_key_name)
      #           .map(&primary_key_name)
      # all_ids = objects.distinct.pluck(primary_key_name)
      all_ids = objects.pluck(primary_key_name).uniq

      results[:indices] = all_ids
                          .each_with_index.reduce({}) do |acc, (object_id, idx)|
                            acc.merge(
                              (offset + idx) => object_id,
                            )
                          end

      [results, objects]
    end
    private :_compose_indices

    # determine the key name for the collection
    #
    # It uses 'objects' as the key for collections with 's=' option.
    # If 's=' is specified, it is assumed to be a collection.
    #
    # DEVIATION WARNING: If an alternate top-level key name for non-collection
    # responses is desired, it can be specified via the :top_level_key option.
    #
    def _compose_ranged_outer_layer(results, objects, _is_collection, _options = {})
      results[:objects] = objects

      [results, objects]
    end
    private :_compose_ranged_outer_layer

    def _compose_outer_layer(results, objects, is_collection, options = {})

      results.merge!(
        if is_collection
          {
            self.class.collection_name => objects,
          }
        else
          tlk = options[:top_level_key]
          if tlk && !tlk.blank?
            {
              tlk => objects[0],
            }
          else
            {
              self.class.instance_name => objects[0],
            }
          end
        end,
      )

      [results, objects]
    end
    private :_compose_outer_layer

    # expect #additional_data to return a hash
    # Pass the object(s) to the method if it expects it.
    #
    # Note that a single instance will still be wrapped inside an array, so
    # that #additional_data can just do #map, #each, etc. on it.
    #
    def _compose_additional_data(results, objects, _is_collection, options = {})

      if options[:additional_data] && respond_to?(:additional_data, true)
        case method(:additional_data).arity
        when 0 then results.merge! additional_data
        else results.merge! additional_data objects
        end
      end

      [results, objects]
    end
    private :_compose_additional_data

    # Create the actual object to be sent to the client, given the resource(s)
    # and options for the output.
    #
    def compose_results_from_options(object_or_objects, options = {})
      # prepare all responses from a simple hash
      results = {}

      # determine if we're given a collection or just a single instance
      # This is used to determine how the object(s) is(are) presented.
      is_collection = object_or_objects.is_a?(ActiveRecord::Relation) ||
                      object_or_objects.is_a?(Enumerable)

      # get ourselves some homogeneous data to work on...
      objects = (is_collection ? object_or_objects : [object_or_objects])
      # compose_types = if objects.respond_to?(:view_order_range)
      is_ranged = !! options[:s]
      compose_types = if is_ranged
                        %i[
                          requested_at
                          range_total
                          indices
                          rejected_ids
                          ranged_outer_layer
                          additional_data
                        ]
                      else
                        %i[
                          outer_layer additional_data
                        ]
                      end

      results, _objects =
        compose_types.inject([results, objects]) do |(res, objs), compose_type|
          send(:"_compose_#{compose_type}", res, objs, is_collection, options)
        end

      # return it!
      results
    end

  end
end
