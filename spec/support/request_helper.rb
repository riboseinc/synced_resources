# (c) Copyright 2017 Ribose Inc.
#

require "action_dispatch/testing/integration"
require "rspec/rails"

module RequestHelper
  def time_to_stamp(time)
    (time.to_f * 1000).to_i - SyncedResources.base_time
  end

  # JSON-HTTP Request!
  #
  # TODO Actually, it should in the opposite way.  That is, the arguments list
  # should resemble these new-fashioned keyword-arguments-based methods
  # of Rails 5.
  def jhr(method, action, params = {}, session = nil)
    case Rails::VERSION::MAJOR
    when 4
      xhr method, action, { format: "json" }.merge(params), session
    else
      public_send method, action, params: { xhr: true, format: "json" }.merge(params), session: session
    end
  end

  # define #jindex, #jshow, #jupdate, #jdestroy & #jcreate
  {
    index:   :get,
    show:    :get,
    new:     :get,
    update:  :put,
    destroy: :delete,
    create:  :post,
  }.each_pair do |action, method|

    # Showing the commented-out generated method signatures here for easier
    # search.

    # def jshow(params = {})
    # def jnew(params = {})
    # def jupdate(params = {})
    # def jdestroy(params = {})
    # def jcreate(params = {})
    # def jindex(params = {})

    eval <<-SDF
      def j#{action}(params = {}, session = nil)
        jhr(#{method.inspect}, #{action.inspect}, params, session)
      end
    SDF
  end

  # define #jget, #jput, #jdelete, #jpost
  %i[get put delete post].each do |method|
    # Showing the commented-out generated method signatures here for easier
    # search.

    # def jput(action, params = {})
    # def jdelete(action, params = {})
    # def jpost(action, params = {})
    # def jget(action, params = {})

    eval <<-SDF
      def j#{method}(action, params = {}, session = nil)
        jhr(#{method.inspect}, action, params, session)
      end
    SDF
  end
end
