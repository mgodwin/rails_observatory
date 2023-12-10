desc "Explaining what the task does"
task consume: :environment do
  puts "Starting library dispatch consumer"
  $redis.with do |r|
      begin
        r.call('XGROUP', 'CREATE', 'events', 'firehose_group', '0', 'MKSTREAM')
      rescue RedisClient::CommandError => e
        raise e unless e.message == 'BUSYGROUP Consumer Group name already exists'
      end
    loop do
      res = r.call("XREADGROUP", "GROUP", 'firehose_group', 'rake', "COUNT", 1, "STREAMS", "events", '>')
      if res.nil?
        puts 'no events'
        sleep 1
        next
      end
      puts "Received #{res}"
      res['events'].each do |e|
        tsid, kv = e
        hash = Hash[*kv]
        hash['payload'] = JSON.parse(hash['payload'])

        event_name, library = hash['event'].split('.')
        r.call('XADD', library, '*', 'name', event_name, 'payload', JSON.generate(hash['payload']), 'duration', hash['duration'], 'ts', tsid.split('-').first)
        puts "added #{event_name} to #{library} stream"
      end
    end
  end
end
