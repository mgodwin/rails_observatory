class ScenariosController < ApplicationController
  skip_forgery_protection

  # GET /scenarios/success - 200 HTML response
  def success
    @message = "Success response"
    logger.info "Processing success action"
  end

  # GET /scenarios/success_json - 200 JSON response
  def success_json
    logger.info "Processing JSON success action"
    render json: {status: "ok", message: "JSON success response", timestamp: Time.current}
  end

  # POST /scenarios/create_resource - 201 created response
  def create_resource
    logger.info "Creating resource"
    post = Post.create!(title: "Seeded Post #{SecureRandom.hex(4)}", body: "Auto-generated content")
    render json: {id: post.id, title: post.title}, status: :created
  end

  # PATCH /scenarios/update_resource - 200 updated response
  def update_resource
    logger.info "Updating resource"
    post = Post.first_or_create!(title: "Default Post", body: "Default body")
    post.update!(body: "Updated at #{Time.current}")
    render json: {id: post.id, updated_at: post.updated_at}, status: :ok
  end

  # DELETE /scenarios/delete_resource - 204 no content response
  def delete_resource
    logger.info "Deleting resource"
    Post.where(title: "Temporary Post").destroy_all
    head :no_content
  end

  # GET /scenarios/not_found - 404 response
  def not_found
    logger.warn "Looking for non-existent record"
    raise ActiveRecord::RecordNotFound, "Could not find Post with id=999999"
  end

  # POST /scenarios/validation_error - 422 response
  def validation_error
    logger.warn "Validation error scenario"
    render json: {errors: ["Title can't be blank", "Body is too short"]}, status: :unprocessable_entity
  end

  # GET /scenarios/server_error - 500 response
  def server_error
    logger.error "About to raise server error"
    raise StandardError, "Simulated server error for testing"
  end

  # GET /scenarios/slow_request - slow response (2-3 seconds)
  def slow_request
    duration = rand(2.0..3.0)
    logger.info "Starting slow request (#{duration.round(2)}s)"
    sleep(duration)
    logger.info "Slow request completed"
    render json: {status: "ok", duration: duration.round(2)}
  end

  # POST /scenarios/unpermitted_params - triggers unpermitted_parameters event
  def unpermitted_params
    permitted = params.require(:post).permit(:title)
    render json: {permitted: permitted.to_h}
  end
end
