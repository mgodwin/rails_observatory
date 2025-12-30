class RetryJob < ApplicationJob
  queue_as :default

  class RetryableError < StandardError; end

  retry_on RetryableError, wait: 0.seconds, attempts: 5

  def perform(fail_times:)
    # Track attempts using job's executions count
    logger.info "Attempt #{executions} - will fail #{fail_times} times total"

    if executions <= fail_times
      logger.warn "Simulating failure #{executions}/#{fail_times}"
      raise RetryableError, "Simulated failure attempt #{executions}"
    end

    logger.info "Success on attempt #{executions}!"
    true
  end
end
