module RailsObservatory

  class EventCollection
    include Enumerable

    attr_accessor :events

    delegate :push, :<<, :size, to: :events
    delegate :empty?, to: :to_a

    def initialize(events)
      @events = events
    end

    def without(*names)
      copy = self.clone
      copy.instance_exec { @without = names }
      copy
    end

    def only(*names)
      copy = self.clone
      copy.instance_exec { @only = names }
      copy
    end

    def each
      decorate_events unless @decorated
      iterating_set = @events
      if @without
        iterating_set = iterating_set.reject { _1['name'].in?(@without) }
      end
      if @only
        iterating_set = iterating_set.select { _1['name'].in?(@only) }
      end
      iterating_set.then(&method(:decorate_with_relative_time)).each { yield _1 }
    end

    def to_series
      all_events = to_a
      min, max = all_events.minmax_by { _1['depth'] }.pluck('depth')

      category_primer = (min..max).map do |depth|
        {
          x: depth.to_s,
          y: nil,
          event_self_time: 0,
        }
      end

      grouped_events = all_events.group_by { _1['name'].split('.').last }.sort_by { _1.first }
      grouped_events.map do |name, events|
        {
          name: name,
          data: category_primer + events.map do |ev|
            {
              x: ev['depth'].to_s,
              y: [ev['relative_start_at'], ev['relative_end_at']],
              event_self_time: ev['self_time'],
              event_name: ev['name'].split('.').first,
              start_at: ev['start_at'],
            }
          end
        }
      end
    end

    def self_time_by_library
      each_with_object(Hash.new(0)) do |event, hash|
        library = event['name'].split('.').last
        hash[library] += event['self_time']
      end
    end



    private

    def decorate_events
      @events = @events.then(&method(:sort_events))
                       .then(&method(:decorate_with_self_time))
                       .then(&method(:merge_middleware))
                       .then(&method(:decorate_with_depth))
      @decorated = true
    end

    def sort_events(events)
      events.sort_by { _1['start_at'] }
    end

    def merge_middleware(events)
      middleware_events = events.select { _1['name'] == 'process_middleware.action_dispatch' }
      return events if middleware_events.empty?
      merged_middleware = middleware_events.reduce(middleware_events.first.without('self_time')) do |merged, event|
        merged['self_time'] ||= 0
        merged['self_time'] += event['self_time']
        merged['middleware_stack'] ||= []
        merged['middleware_stack'] << event
        merged
      end
      [merged_middleware] + events.excluding(middleware_events)
    end

    def decorate_with_depth(events)
      depth_stack = [] 
      events.each do |e|
        event_range = (e['start_at']..e['end_at'])
        depth_stack.select! { _1.cover?(event_range) }
        e['depth'] = depth_stack.size
        depth_stack << event_range
      end
    end

    def decorate_with_self_time(events)
      events.each do |ev|
        ev_range = (ev['start_at']..ev['end_at'])
        sub_events = events.excluding(ev).select { ev_range.cover?(_1['start_at'].._1['end_at']) }
        sub_event_time = non_overlapping_ranges(sub_events).reduce(0) { |sum, range| sum + (range.end - range.begin) }
        ev['self_time'] = ev['duration'] - sub_event_time
      end
    end

    def non_overlapping_ranges(events)
      events.reduce([]) do |arr, event|
        event_range = (event['start_at']..event['end_at'])
        if arr.any? { |r| r.cover?(event_range) }
          arr
        else
          arr << event_range
        end
      end
    end

    def decorate_with_relative_time(events)
      return events if events.empty?
      first_event = events.first['start_at']
      events.each do |ev|
        ev['relative_start_at'] = ev['start_at'] - first_event
        ev['relative_end_at'] = ev['end_at'] - first_event
      end
    end

  end
end