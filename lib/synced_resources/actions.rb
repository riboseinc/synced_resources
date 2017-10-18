# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  module Actions
    #
    # override-able RESTful responses
    #
    # Only use the given block if given.
    #
    def create
      if block_given?
        super
      else
        super do |success, failure|
          respond_with_resources.call(success, failure)
        end
      end
    end

    def show
      if block_given?
        super
      else
        # https://github.com/puppetlabs/puppet-dashboard/pull/146
        # seems this only takes 1 argument ... starting from Ruby1.9
        super do |format|
          respond_with_resources.call(format)
        end
      end
    end

    def update
      if block_given?
        super
      else
        super do |success, failure|
          respond_with_resources(action: :update).call(success, failure)
        end
      end
    end

    def destroy
      if block_given?
        super
      else
        super do |success, failure|
          respond_with_resources(action: :destroy).call(success, failure)
        end
      end
    end

    def index
      if block_given?
        super
      else
        super &respond_with_resources(collection)
      end
    end
  end
end
