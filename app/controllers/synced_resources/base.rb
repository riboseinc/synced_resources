# (c) Copyright 2017 Ribose Inc.
#

require "action_controller"

module SyncedResources
  class Base < ::ApplicationController # InheritedResources::Base

    def self.synced_resources(base)
      base.class_eval do
        inherit_resources
        include SyncedResources::Actions
        include SyncedResources::BaseHelpers
        include SyncedResources::ViewHelpers
        extend SyncedResources::ClassMethods
      end
    end

    def self.inherited(base)
      synced_resources(base)
    end

  end
end
