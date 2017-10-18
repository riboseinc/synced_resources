class DummyController < SyncedResources::Base
  before_filter :forbid_guest_user!, except: :index
  defaults resource_class: DummyResource

  def index
    super &respond_with_resources(
      collection,
      start:             params[:start].to_i,
      length:            params[:length].to_i,
      s:                 params[:s],
      additional_data:   true,
    )
  end

  def collection
    DummyResource.all
  end
end
