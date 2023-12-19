desc "Explaining what the task does"
task consume: :environment do
  puts "Starting stream worker"
  RailsObservatory::StreamWorker.new('primary').work
end
