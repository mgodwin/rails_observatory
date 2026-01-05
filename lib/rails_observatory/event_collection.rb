module RailsObservatory
  class EventCollection
    include Enumerable

    attr_writer :events

    def initialize(events)
      @events = events.deep_dup
      @_sorted = false
    end

    def initialize_copy(original)
      super
      @events = original.instance_variable_get(:@events).deep_dup
      @processed = false
    end

    def events
      return @events if @processed
      process_events
      @events
    end

    def find(start_at)
      needle = start_at.to_f
      to_a.find { it["start_at"] == needle }
    end

    def without(*names)
      copy = clone
      copy.instance_exec do
        events.reject! { it["name"].in?(names) }
      end
      copy
    end

    def only(*names)
      copy = clone
      copy.instance_exec do
        events.select! { it["name"].in?(names) }
      end
      copy
    end

    def flatten_middleware
      copy = clone
      copy.instance_exec do
        merge_middleware_events!
      end
      copy
    end

    def size
      to_a.size
    end

    def each
      events.each { yield it }
    end

    def to_series
      all_events = to_a
      min, max = all_events.minmax_by { it["depth"] }.pluck("depth")

      category_primer = (min..max).map do |depth|
        {
          x: depth.to_s,
          y: nil,
          event_self_time: 0
        }
      end

      grouped_events = all_events.group_by { it["name"].split(".").last }.sort_by { it.first }
      grouped_events.map do |name, events|
        {
          name: name,
          data: category_primer + events.map do |ev|
            {
              x: ev["depth"].to_s,
              y: [ev["relative_start_at"], ev["relative_end_at"]],
              event_self_time: ev["self_time"],
              event_name: ev["name"].split(".").first,
              start_at: ev["start_at"]
            }
          end
        }
      end
    end

    def self_time_by_library
      each_with_object(Hash.new(0)) do |event, hash|
        library = event["name"].split(".").last
        hash[library] += event["self_time"]
      end
    end

    private

    def sort_events(events)
      events.sort_by { it["start_at"] }
    end

    def merge_middleware_events!
      middleware_events = events.select { it["name"] == "process_middleware.action_dispatch" }

      midddleware_depth = middleware_events.map { it["depth"] }.max
      merged_middleware = {
        "name" => "process_middleware.action_dispatch",
        "start_at" => middleware_events.map { it["start_at"] }.min,
        "end_at" => middleware_events.map { it["end_at"] }.max,
        "relative_start_at" => middleware_events.map { it["relative_start_at"] }.min,
        "relative_end_at" => middleware_events.map { it["relative_end_at"] }.max,
        "duration" => middleware_events.first["duration"],
        "depth" => 0,
        "self_time" => middleware_events.sum { it["self_time"] },
        "middleware_stack" => middleware_events
      }

      other_events = events.excluding(middleware_events)
      other_events.each do |event|
        next if event["depth"] <= midddleware_depth
        event["depth"] -= midddleware_depth
        event["depth"] = 1 if event["depth"] <= 1
      end

      self.events = [merged_middleware, *other_events]
    end

    # Self time is the time spent in an event excluding time spent in child events.
    def process_events
      return if @processed || @events.empty?
      timeline = []
      @events.each do |ev|
        timeline << {time: ev["start_at"], type: :start, event: ev}
        timeline << {time: ev["end_at"], type: :end, event: ev}
      end

      timeline.sort_by! { |entry| entry[:time] }

      start_time = timeline.first[:time]
      active_events = [timeline.first[:event]]
      previous_time = start_time

      timeline.slice(1..).each do |entry|
        duration = (entry[:time] - previous_time) * 1000.0
        if active_events.last
          active_events.last["self_time"] ||= 0
          active_events.last["self_time"] += duration
        end

        if entry[:type] == :start
          active_events << entry[:event]
        elsif entry[:type] == :end
          active_events.last["relative_start_at"] = (active_events.last["start_at"] - start_time) * 1000.0
          active_events.last["relative_end_at"] = (active_events.last["end_at"] - start_time) * 1000.0
          active_events.last["depth"] = active_events.size
          active_events.pop
        end

        previous_time = entry[:time]
      end

      @events.sort_by! { it["start_at"] }
      @processed = true
    end
  end
end
