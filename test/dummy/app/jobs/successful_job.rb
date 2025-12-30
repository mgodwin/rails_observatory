class SuccessfulJob < ApplicationJob
  queue_as :default

  def perform(name:)
    logger.info "Starting job: #{name}"
    sleep(rand(0.1..0.5)) # Simulate work
    logger.info "Processing #{name}..."
    sleep(rand(0.1..0.3))
    logger.info "Completed job: #{name}"
    true
  end
end
