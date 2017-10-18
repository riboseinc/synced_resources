# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  module ViewScopable
    def self.included(base)
      base.class_eval do
        scope :view_all, lambda { |view_presenter|
          # Using group together with count will return a hash instead of a
          # numeric result.  We prevent that by disabling the group here
          # TODO: check if this disabling of group breaks any case
          # group(t[primary_key]).
          view_filter(view_presenter)
        }

        scope :view_filter, lambda { |view_presenter|
          composed = all

          # filter out ids if provided
          ids = view_presenter.params[:ids]
          if ids
            ids = ids.split(",")
            composed = composed.where(id: ids)
          end

          # apply filter if exists
          if view_presenter.filter
            composed = composed.filter_by_params(view_presenter.filter)
          end

          # TODO: tag filtering should be done here
          #   or: find_records_filtered_by_tag(view, options)
          if view_presenter.tags_applied?
            composed = composed.filter_tags(view_presenter)
          end

          composed
        }

        # Sets the order and range of records using params from the view_presenter
        scope :view_order_range, lambda { |view_presenter|
          # NOTE: Arel.star messes up .count by injecting the
          # Ruby-write-expression into the SQL statement.
          #
          # select(arel_table[Arel.star]).
          view_order(view_presenter).
            view_range(view_presenter)
        }

        # Sets the maximum number of records using params from the view_presenter
        scope :view_range, lambda { |view_presenter|
          offset(view_presenter.start).
            limit(view_presenter.length)
        }

        # Sets the order of records using params from the view_presenter
        scope :view_order, lambda { |view_presenter|
          view_special_order(view_presenter.order_by, view_presenter.direction)
        }

        # Override this if your 'order_by' parameter name doesn't match any of
        # the field names.
        scope :view_special_order, lambda { |order_by, direction|
          view_normal_order(order_by, direction)
        }

        # Internal method that sets the order of records, called by
        # view_special_order in model
        scope :view_normal_order, lambda { |order_by, direction|
          # ordered by special (non-column-names, may require selects and joins)
          # normal ordered by (order by column-names)
          if column_names.include?(order_by.to_s)
            order(order_by.to_sym => direction.downcase.to_sym)
          # no specified order
          else
            all
          end.group(arel_table[primary_key])
        }
      end
    end
  end
end
