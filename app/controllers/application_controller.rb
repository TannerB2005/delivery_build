class ApplicationController < ActionController::API
  # Global error handling for better debugging
  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  private

  def handle_not_found(exception)
    render json: {
      error: "Resource not found",
      message: exception.message
    }, status: :not_found
  end

  def handle_parameter_missing(exception)
    render json: {
      error: "Missing required parameter",
      message: exception.message
    }, status: :bad_request
  end

  def handle_internal_error(exception)
    Rails.logger.error "Internal Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    render json: {
      error: "Internal server error",
      message: Rails.env.development? ? exception.message : "Something went wrong"
    }, status: :internal_server_error
  end
end
