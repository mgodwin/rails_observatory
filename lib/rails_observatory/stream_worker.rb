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
            # Processor.process_event(event) if Processor.can_process?(event)
            # RequestEventSet.new(event.request_id).add(event) if event.respond_to?(:request_id)
          end
        end
        sleep 0.1 if count == 0
      end
    end

  end
end