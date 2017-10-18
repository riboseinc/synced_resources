# (c) Copyright 2017 Ribose Inc.
#

module SyncedResources
  module ViewHelpers
    protected

    def self.included(base)
      base.class_eval do
        def view
          @view_presenter ||= ViewPresenter.new(
            params,
            respond_to?(:list_options, true) ? list_options : {},
          )
        end
        helper_method :view
        private :view
      end
    end
  end
end
