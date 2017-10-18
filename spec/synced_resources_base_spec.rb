# (c) Copyright 2017 Ribose Inc.
#

require "spec_helper"
require "active_record"

RSpec.describe SyncedResources::Base, type: :controller do
  shared_context "with sync_str" do
    before do
      resource_sets = 4
      set_size      = 5

      resource_sets.times do |i|
        update_time = current_time - (resource_sets - i - 1).hours
        resource_class.add(
          set_size,
          update_time,
        )
      end
    end
  end

  shared_context "with sync_str worth checking" do
    include_context "with sync_str"

    before do
      jindex options.merge(s: SyncedResources.sync_string_encoder.call(sync_hash))
    end
  end

  shared_context "skip responding resources included in the sync_str of a synced_at" do
    include_context "with sync_str worth checking"

    let(:options) { { start: 10, length: 10 } }

    let(:sync_hash) do
      {}.tap do |h|
        5.times do |i|
          id = i + options[:start] + 1
          h[id] = time_to_stamp(current_time + 10.hours)
        end
      end
    end
  end

  shared_context "skip responding resources included in the sync_str of continuous ids" do
    include_context "with sync_str worth checking"

    let(:options) { { start: 10, length: 10 } }

    let(:sync_hash) do
      {}.tap do |h|
        5.times do |i|
          2.times do |j|
            id = i * 2 + j + options[:start] + 1
            h[id] = time_to_stamp(current_time - i.hours)
          end
        end
      end
    end
  end

  shared_context "skip responding resources included in the sync_str of discrete ids" do
    include_context "with sync_str worth checking"

    let(:options) { { start: 10, length: 10 } }

    let(:sync_hash) do
      timestamps = []

      4.times do |i|
        timestamps << time_to_stamp(current_time - i.hours)
      end

      {
        2  => timestamps[0],
        9  => timestamps[0],
        10 => timestamps[0],
        13 => timestamps[1],
        15 => timestamps[2],
        20 => timestamps[3],
      }
    end
  end

  shared_examples_for "a resource controller" do
    let(:resource_class) do
      described_class.to_s.constantize.resource_class
    end

    let(:current_time) { resource_class.current_time }

    shared_examples_for "all successful responses" do
      subject { response }
      it { is_expected.to be_success }
    end

    shared_examples_for "all resourceful responses" do |objects_length = nil|
      it_behaves_like "all successful responses"

      it "has :total equal to number of all resources" do
        expect(response_hash["total"]).to eq resource_class.all.length
      end

      it "has :indices with size equal to number in options[:length]" do
        expect(response_hash["indices"].length).to eq options[:length]
      end

      it "has same number of objects as specified" do
        objects_length ||= options[:length]
        expect(response_hash["objects"].length).to eq objects_length
      end

      it "has :requested_at" do
        expect(response_hash).to have_key "requested_at"
      end
    end

    let(:response_hash) { JSON.parse(response.body) }

    context "without sync_str" do
      before do
        resource_class.add 20, current_time
        jindex
      end

      it_behaves_like "all successful responses"

      # it "has :#{resources_name}" do
      it "has the resources_name as the key" do
        expect(response_hash).to have_key resources_name
      end

      it "has same number of objects in the resources_name key" do
        expect(response_hash[resources_name].length).to eq resource_class.all.length
      end
    end

    context "with empty sync_str" do
      include_context "with sync_str"

      let(:options) { { s: "", start: 0, length: 5 } }

      before do
        jindex options
      end

      it_behaves_like "all resourceful responses"

      it "has objects that are covered in range by options" do
        range_start = options[:start] + 1
        range_end   = range_start + options[:length] - 1
        range       = range_start..range_end

        response_hash["objects"].each do |obj|
          expect(range).to be_cover obj["id"]
        end
      end
    end

    context "invalid sync_str" do
      include_context "with sync_str"

      shared_examples_for "all invalid sync str responses" do |s|
        let(:options) { { s: s, start: 10, length: 10 } }

        it_behaves_like "all successful responses"

        it "ignores the sync str" do
          response_object_ids = response_hash["objects"].map do |obj|
            obj["id"]
          end

          expect(response_object_ids).to eq((11..20).to_a)
        end
      end

      before do
        jindex options
      end

      it_behaves_like "all invalid sync str responses", "omgwtfbbq"
      it_behaves_like "all invalid sync str responses", '/#@$#,_T~B,0'
      it_behaves_like "all invalid sync str responses", "1439524794175,_T~B,"

      # obviously incorrect
      it_behaves_like "all invalid sync str responses", "1439524794175,_T~121.23!1B,0"
    end
  end

  def resources_name
    # described_class.resource_class.name.pluralize.underscore
    described_class.to_s.constantize.resource_class.name.pluralize.underscore
  end

  # URL:
  # http://blog.spoolz.com/2015/02/05/create-an-in-memory-temporary-activerecord-table-for-testing/
  before(:all) do
    # don't output all the migration activity
    # ActiveRecord::Migration.verbose = false

    begin
      ActiveRecord::Schema.define(version: 1) do
        drop_table :dummy_resources
      end
    rescue => e
      warn e.backtrace
    end

    ActiveRecord::Schema.define(version: 1) do
      create_table :dummy_resources do |t|
        t.datetime :updated_at
        t.datetime "created_at"
      end
    end
  end

  before do
    begin
      %w[
        dummy_resources
      ].each do |table_name|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
      end
    rescue => e
      warn e.message
    end
  end

  describe DummyController do
    it_behaves_like "a resource controller" do
      context do
        include_context "skip responding resources included in the sync_str of a synced_at" do
          it_behaves_like "all resourceful responses", 5

          it "contains only 16..20 in :objects" do
            response_object_ids = response_hash["objects"].map do |obj|
              obj["id"]
            end

            expect(response_object_ids).to eq (16..20).to_a
          end
        end
      end

      context do
        include_context "skip responding resources included in the sync_str of continuous ids" do
          it_behaves_like "all resourceful responses", 6

          it "contains only 15..20 in :objects" do
            response_object_ids = response_hash["objects"].map do |obj|
              obj["id"]
            end

            expect(response_object_ids).to eq (15..20).to_a
          end
        end
      end

      context do
        include_context "skip responding resources included in the sync_str of discrete ids" do
          it_behaves_like "all resourceful responses", 9

          it "does not contain #13 in :objects" do
            response_object_ids = response_hash["objects"].map do |obj|
              obj["id"]
            end

            expect(response_object_ids).to_not be_include 13
          end
        end
      end
    end
  end
end
