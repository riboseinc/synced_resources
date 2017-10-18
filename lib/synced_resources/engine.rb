# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  class Railtie < ::Rails::Engine
    config.synced_resources = SyncedResources
  end
end
