# simulate_traffic.rb

require 'active_support/notifications'
require 'faker'

# Define the number of events you want to emit
EVENT_COUNT = 100

# Possible HTTP methods and statuses
HTTP_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH"]
HTTP_STATUSES = [200, 201, 204, 400, 401, 403, 404, 500]

Faker::Config.random = Random.new(42)
names = (0..30).map { Faker::App.name }
controller_actions = ["index", "show", "create", "update", "destroy", "new", "edit"]

EVENT_COUNT.times do |i|
  # Use Faker to generate controller names like "UsersController", "ProductsController", etc.
  controller_name = "#{names.sample}Controller"

  # Randomly select a method and status
  method = HTTP_METHODS.sample
  status = HTTP_STATUSES.sample

  id = rand(1..1000)
  # Simulating some dynamic payload data
  payload = {
    controller: controller_name,
    action: controller_actions.sample, # Generate random action name
    params: { "id" => id },
    format: :html,
    method: method,
    path: "/#{controller_name.underscore}/#{id}",
    status: status,
    view_runtime: rand(10..100),
    db_runtime: rand(1..10)
  }

  # Define start and finish times to calculate duration
  # start_time = Time.now
  # Simulate the duration by adding a random number of seconds
  # finish_time = start_time + rand(0.1..1.5)

  # Publish the event
  ActiveSupport::Notifications.instrument('process_action.action_controller', payload)

  puts "Emitted event ##{i + 1} with payload: #{payload}"
end

puts "Done"
