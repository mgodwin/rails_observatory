module RailsObservatory
  class RedisStream

    def self.add_to_stream(type:, duration:, payload:)
      $redis.call('XADD', stream_name, '*', 'type', type, 'payload', JSON.generate(payload), 'duration', duration)
    end

    def self.stream_info
      $redis.call('XINFO', 'STREAM', stream_name)
    end

    def self.stream_name
      self.name.demodulize.tableize
    end

    def self.create_read_group_if_not_exists(group_name)
      begin
        $redis.call('XGROUP', 'CREATE', stream_name, group_name, '0', 'MKSTREAM')
      rescue RedisClient::CommandError => e
        raise e unless e.message == 'BUSYGROUP Consumer Group name already exists'
      end
    end

    def self.unread_for(group_name)
      return enum_for(:unread_for, group_name) unless block_given?

      create_read_group_if_not_exists(group_name)
      reader_name = "#{Process.pid}-#{Thread.current.native_thread_id}"
      loop do
        res = $redis.call("XREADGROUP", "GROUP", group_name, reader_name, "COUNT", 1, "STREAMS", stream_name, '>')
        break if res.nil?
        event = StreamEvent.from_redis(res[stream_name].first)
        yield event
        $redis.call('XACK', stream_name, group_name, event.id)
      end
    end

    def self.unread_for_blocking(group_name) end

    def self.all(&blk)
      return enum_for(:all).lazy unless block_given?
      id = "+"
      loop do
        raw_events = $redis.call("XREVRANGE", stream_name, id, "-", "COUNT", "1000")
        break if raw_events.empty?
        events = raw_events.map { StreamEvent.from_redis(_1) }.each(&blk)
        id = "(#{events.last.id}"
      end
    end

  end
end