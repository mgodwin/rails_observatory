module RailsObservatory

  class StreamWorker

    def initialize(reader)
      @reader = reader
    end

    def streams
      @streams ||= Rails.configuration.rails_observatory.streams.map { "RailsObservatory::#{_1.to_s.camelize}Stream".constantize }
    end

    def work
      loop do
        count = 0
        streams.each do |stream|
          stream.next_unread_for('processor', @reader) do |event|
            puts "Processing #{event.class.name}"
            count += 1
            event.process
          end
        end
        sleep 0.1 if count == 0
      end
    end

  end
end