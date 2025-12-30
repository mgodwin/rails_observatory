class FailingJob < ApplicationJob
  queue_as :default

  def perform(reason:)
    logger.info "Starting failing job"
    logger.warn "About to fail: #{reason}"
    sleep(rand(0.1..0.3)) # Simulate some work before failure
    raise StandardError, reason
  end
end
