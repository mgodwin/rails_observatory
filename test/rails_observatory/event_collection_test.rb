require 'test_helper'

module RailsObservatory
  class EventCollectionTest < ActiveSupport::TestCase
    def events
      @events ||= JSON.parse(file_fixture("sample_request_events.json").read)
    end

    test "it works" do
      collection = EventCollection.new(events)
      total_duration = collection.to_a.first['duration']
      self_duration = collection.to_a.reduce(0) { |sum, event| sum + event['self_time'] }
      assert_equal total_duration.to_i, self_duration.to_i
    end

    test 'it returns the correct number of events' do
      collection = EventCollection.new(events)
      assert_equal 55, collection.size
    end

    test 'flattening middleware' do
      collection = EventCollection.new(events)
      flattened = collection.flatten_middleware
      assert_equal 30, flattened.size
    end
  end
end
