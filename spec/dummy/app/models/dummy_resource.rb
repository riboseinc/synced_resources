class DummyResource < ActiveRecord::Base
  include SyncedResources::ViewScopable

  def self.current_time
    @current_time ||= Time.now + 1.day
  end

  def self.add(count, time)
    count.times do
      create(updated_at: time)
    end
  end

end
