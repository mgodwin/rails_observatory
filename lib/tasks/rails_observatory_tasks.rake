desc "Explaining what the task does"
task consume: :environment do
  puts "Starting library dispatch consumer"
  RailsObservatory::RequestsStream.unread_for('processor').each do |event|
    puts "Processing event #{event.id}"
    event.record_metrics
  end

  # Iterate down the stream
  # Concurrency is the problem
  #   In particular, you can't rely on the order of the messages.
  #     - You could just filter the entire stream
  #       - this is slow
  #   Bob and alice would need to coordinate to ensure timestamps are the same.
  puts "Done"
end
