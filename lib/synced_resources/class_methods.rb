# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  module ClassMethods
    # TODO: Make this 'protected' work:
    # protected

    # 'base_time' is used to normalize the synchronization times of your
    # collection.
    #
    # Configure it via SyncedResources.base_time.
    def base_time
      SyncedResources.base_time
    end

    def time_to_synced_at time = Time.now.utc
      SyncedResources.time_to_synced_at(time)
    end

    # Decode_sync_str already adds VERSION.last_committed_at for us
    def synced_at_to_time(synced_at, base_time = 0)
      Time.at((synced_at + base_time) / 1000.0).utc
    end

    # Infer collection name from #instance_name
    def collection_name
      instance_name.pluralize
    end

    # Infer instance name from #resource_class
    def instance_name
      resource_class.name.demodulize.underscore
    end

    # Change behaviour for the resource path method generation of
    # InheritedResources.
    #
    # == NOTE
    # If `nested_belongs_to' is needed, it has to be called -before- this.
    #
    # == Example
    #
    # @ config/routes.rb,
    #
    # namespace :foo { resources :bars {...} }
    # # Note: :foo_bars vs :bars
    #
    # @ app/controllers/foo/foo_bars_controller.rb,
    #
    # class Foo::FooBarsController < ResourceController
    #   route_is_defined_as 'bars'
    #   # matches the `resources :bars' in routes
    # end
    #
    #
    # == Example
    #
    # @ config/routes.rb,
    #
    # namespace :foo { resources :barbaz {...} }
    # # Note: :bar_baz vs :barbaz
    #
    # @ app/controllers/foo/bar_baz_controller.rb,
    #
    # class Foo::BarBazController < ResourceController
    #   route_is_defined_as 'barbaz'
    #   # matches the `resources :barbaz' in routes
    # end
    #
    def route_is_defined_as(string)
      collection_name = controller_path.split("/")[0] + "_" + string.pluralize
      instance_name   = collection_name.singularize

      # prevent stuff like `tasks_space_tasks_bug_path'
      defaults route_prefix:          nil,
               route_collection_name: collection_name,
               route_instance_name:   instance_name
    end

    # Coax InheritedResources into spitting out the correct resource path
    # method
    # names.
    #
    def inherited(base)
      super
      collection_name = base.controller_path.
        tr("/", "_").
        pluralize
      instance_name   = collection_name.singularize

      # Check if `nested_belongs_to' has been called with > 1 args.
      # If so, prefix the names with the most immediate ancestor (i.e. the
      # parent).
      prefix = if base.parents_symbols.length > 1
                 "#{base.parents_symbols[-1]}_"
               else
                 ""
               end

      # prevent stuff like `tasks_space_tasks_bug_path'
      base.defaults route_prefix:          nil,
                    route_collection_name: prefix + collection_name,
                    route_instance_name:   prefix + instance_name
    end
  end
end
