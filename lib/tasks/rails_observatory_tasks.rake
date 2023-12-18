desc "Explaining what the task does"
task consume: :environment do
  puts "Starting library dispatch consumer"
  RailsObservatory::RequestsStream.unread_for('processor', 'primary').each do |event|
    puts "Processing event request - #{event.id}"
    event.record_metrics
  end

  RailsObservatory::ErrorsStream.unread_for('processor', 'primary').each do |event|
    puts "Processing event error - #{event.id}"
    event.process
  end
  puts "Done"
end
