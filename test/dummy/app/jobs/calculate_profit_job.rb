class CalculateProfitJob < ApplicationJob
  queue_as :default

  def perform(*args)
    logger.info "Step 1: Run Job"
    logger.info "Step 3: Profit"
  end
end
