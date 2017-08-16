require "spec_helper"

RSpec.describe SyncedResources do
  it "has a version number" do
    expect(SyncedResources::VERSION).not_to be nil
  end
end
