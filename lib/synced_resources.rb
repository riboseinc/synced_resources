# (c) Copyright 2017 Ribose Inc.
#

require "responders"
require "action_view"
require "inherited_resources"
require "synced_resources/engine"

module SyncedResources
  autoload :Actions,       "synced_resources/actions"
  autoload :BaseHelpers,   "synced_resources/base_helpers"
  autoload :ClassMethods,  "synced_resources/class_methods"
  autoload :VERSION,       "synced_resources/version"
  autoload :ViewHelpers,   "synced_resources/view_helpers"
  autoload :ViewPresenter, "synced_resources/view_presenter"
  autoload :ViewScopable,  "synced_resources/view_scopable"

  class << self
    attr_accessor :base_time, :sync_string_encoder, :sync_string_decoder
  end

  # +base_time+ is like a y-intercept.  It is used for the normalization of the
  # client-side synced_at times for objects.
  #
  # A default is being set here.
  # One may want to override it to something like the last Git commit time in a
  # config/initializer.
  @base_time = Time.new(2017, 1, 1, 0, 0, 0, 0).to_i * 1000

  # Encode a Hash { object id => time of object retrieval }.
  #
  # Typically done on the client side.  Its result is then to be sent to the
  # server so the server could determine which other objects the client needs.
  @sync_string_encoder = lambda { |id_to_synced_at_map|
    require "json"
    id_to_synced_at_map.to_json
  }

  # Return a Hash { object id => time of object client retrieval }.
  #
  # Add +base_time+ to the individual synced_at values to restore the actual
  # Time values.
  @sync_string_decoder = lambda { |encoded_map, base_time|
    require "json"
    begin
      JSON.parse(encoded_map).each_with_object({}) do |(k, v), acc|
        acc[k] = v + base_time
      end
    rescue JSON::ParserError
      {}
    end
  }
end

ActiveSupport.on_load(:action_controller) do
  # We can remove this check and change to `on_load(:action_controller_base)` in Rails 5.2.
  if self == ActionController::Base
    # If you cannot inherit from SyncedResources::Base you can call
    # synced_resources in your controller to have all the required modules
    # and funcionality included.
    def self.synced_resources
      SyncedResources::Base.synced_resources(self)
    end
  end
end
