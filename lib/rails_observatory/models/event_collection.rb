module RailsObservatory

  class EventCollection
    include Enumerable

    attr_accessor :events

    delegate :push, :<<, :size, to: :events

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
      grouped_events = to_a.group_by { _1['name'].split('.').last }
      grouped_events.map do |name, events|
        {
          name: name,
          data: events.map do |ev|
            {
              x: ev['depth'].to_i.to_s,
              y: [ev['relative_start_at'], ev['relative_end_at']],
              event_self_time: ev['self_time'],
              event_name: ev['name'].split('.').first,
              start_at: ev['start_at'],
            }
          end
        }
      end
    end



    private

    def decorate_events
      @events = @events.then(&method(:sort_events))
                       .then(&method(:decorate_with_depth))
                       .then(&method(:decorate_with_self_time))
      @decorated = true
    end

    def sort_events(events)
      events.sort_by { _1['start_at'] }
    end

    def decorate_with_depth(events)
      events.each_cons(2) do |a, b|
        if b['start_at'] > a['start_at'] && b['end_at'] < a['end_at']
          b['depth'] = a['depth'].to_i + 1
        else
          b['depth'] = a['depth']
        end
      end
    end

    def decorate_with_self_time(events)
      events.each do |ev|
        ev['self_time'] = ev['duration'] - events.select { _1['depth'] == (ev['depth'].to_i + 1) && _1['end_at'] < ev['end_at'] }.pluck('duration').sum
      end
    end

    def decorate_with_relative_time(events)
      first_event = events.first['start_at']
      events.each do |ev|
        ev['relative_start_at'] = ev['start_at'] - first_event
        ev['relative_end_at'] = ev['end_at'] - first_event
      end
    end

  end
end