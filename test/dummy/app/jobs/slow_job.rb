class SlowJob < ApplicationJob
  queue_as :default

  def perform(duration:)
    logger.info "Starting slow job (#{duration}s duration)"
    sleep(duration)
    logger.info "Slow job completed after #{duration}s"
    true
  end
end
