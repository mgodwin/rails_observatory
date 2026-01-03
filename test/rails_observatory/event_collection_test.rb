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

    # --- Tests for `only` method ---

    test 'only filters to matching event names' do
      collection = EventCollection.new(events)
      sql_events = collection.only('sql.active_record')
      assert_equal 4, sql_events.size
      sql_events.each do |event|
        assert_equal 'sql.active_record', event['name']
      end
    end

    test 'only with multiple names' do
      collection = EventCollection.new(events)
      filtered = collection.only('sql.active_record', 'call.redis')
      assert_equal 24, filtered.size # 4 sql + 20 redis
      filtered.each do |event|
        assert_includes ['sql.active_record', 'call.redis'], event['name']
      end
    end

    test 'only returns empty collection when no matches' do
      collection = EventCollection.new(events)
      filtered = collection.only('nonexistent.event')
      assert_equal 0, filtered.size
    end

    test 'only does not mutate original collection' do
      collection = EventCollection.new(events)
      original_size = collection.size

      _filtered = collection.only('sql.active_record')

      assert_equal original_size, collection.size, "Original collection was mutated by only()"
    end

    # --- Tests for `without` method ---

    test 'without excludes matching event names' do
      collection = EventCollection.new(events)
      without_sql = collection.without('sql.active_record')
      assert_equal 51, without_sql.size # 55 - 4 = 51
      without_sql.each do |event|
        refute_equal 'sql.active_record', event['name']
      end
    end

    test 'without with multiple names' do
      collection = EventCollection.new(events)
      filtered = collection.without('sql.active_record', 'call.redis')
      assert_equal 31, filtered.size # 55 - 4 - 20 = 31
      filtered.each do |event|
        refute_includes ['sql.active_record', 'call.redis'], event['name']
      end
    end

    test 'without does not mutate original collection' do
      collection = EventCollection.new(events)
      original_size = collection.size

      _filtered = collection.without('sql.active_record')

      assert_equal original_size, collection.size, "Original collection was mutated by without()"
    end

    # --- Tests for `find` method ---

    test 'find returns event by start_at timestamp' do
      collection = EventCollection.new(events)
      first_event = collection.to_a.first
      start_at = first_event['start_at']

      found = collection.find(start_at)

      assert_not_nil found
      assert_equal first_event['name'], found['name']
      assert_equal start_at, found['start_at']
    end

    test 'find returns nil when no match' do
      collection = EventCollection.new(events)
      found = collection.find(0.0)
      assert_nil found
    end

    # --- Tests for `self_time_by_library` ---

    test 'self_time_by_library returns hash of library names to self_time' do
      collection = EventCollection.new(events)
      result = collection.self_time_by_library

      assert_kind_of Hash, result
      assert_includes result.keys, 'active_record'
      assert_includes result.keys, 'redis'
      assert_includes result.keys, 'action_dispatch'
    end

    test 'self_time_by_library sums to total duration' do
      collection = EventCollection.new(events)
      total_duration = collection.to_a.first['duration']
      library_times = collection.self_time_by_library

      sum = library_times.values.sum
      assert_in_delta total_duration, sum, 1.0
    end

    # --- Tests for `flatten_middleware` immutability ---

    test 'flatten_middleware does not mutate original collection' do
      collection = EventCollection.new(events)
      original_size = collection.size

      _flattened = collection.flatten_middleware

      assert_equal original_size, collection.size, "Original collection was mutated by flatten_middleware()"
    end

    # --- Edge case tests ---

    test 'handles empty events array' do
      collection = EventCollection.new([])
      assert_equal 0, collection.size
      assert_equal({}, collection.self_time_by_library)
    end

    test 'handles single event' do
      single_event = [{
        'name' => 'test.event',
        'start_at' => 1000.0,
        'end_at' => 1001.0,
        'duration' => 1000.0,
        'allocations' => 0,
        'failed' => false
      }]
      collection = EventCollection.new(single_event)

      assert_equal 1, collection.size
      processed = collection.to_a.first
      assert_equal 1, processed['depth']
      assert_equal 0.0, processed['relative_start_at']
    end
  end
end
