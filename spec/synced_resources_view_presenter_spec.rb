# (c) Copyright 2017 Ribose Inc.
#

require "spec_helper"

RSpec.describe SyncedResources::ViewPresenter do

  before do
    @list_options = {
      allowed: {
        view:      %w[list expanded thumbnail],
        order_by:  %w[date space file_type],
        direction: %w[asc desc],
      },
      default: {
        view:      "list",
        order_by:  "date",
        direction: "desc",
        page:      "1",
      }
    }
  end

  describe "with empty options" do

    it "should present the list view" do
      @view = SyncedResources::ViewPresenter.new
      expect(@view.to_s).to eq("list")
      expect(@view.all).to eq(%w[list])
    end

  end

  describe "defaults" do

    before do
      @view = SyncedResources::ViewPresenter.new({}, @list_options)
    end

    it "should present the list view" do
      expect(@view.current).to eq("list")
      expect(@view.to_s).to eq("list")
      expect(@view.to_param).to eq("list")
    end

    it "should present the first page" do
      expect(@view.page).to eq("1")
    end

    it "should present direction descending by date" do
      expect(@view.order_by).to eq("date")
      expect(@view.direction.to_s).to eq("desc")
    end

  end

  describe "initialize options" do

    it "should ignore invalid params and use defaults instead" do
      @view = SyncedResources::ViewPresenter.new({ view: "x", order_by: "x", direction: "x", page: "x" }, @list_options)
      expect(@view.to_s).to eq("list")
      expect(@view.order_by).to eq("date")
      expect(@view.direction.to_s).to eq("desc")
      expect(@view.page).to eq("1")
    end

  end

  describe "inquirer" do

    it "should present all allowed views" do
      allowed = %w[list expanded thumbnail]
      @view = SyncedResources::ViewPresenter.new({}, allowed: { view: allowed })
      expect(@view.all).to eq(allowed)
    end

    it "should support view.current?" do
      @view = SyncedResources::ViewPresenter.new(view: "list")
      expect(@view.current?("list")).to be true
      expect(@view.current?("x")).to be false
    end

  end

end
