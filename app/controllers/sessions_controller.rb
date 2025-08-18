class SessionsController < ApplicationController
  def create
    payload = params[:user] || params
    email = payload[:email].to_s.strip.downcase
    password = payload[:password].to_s

    if email.blank? || password.blank?
      return render json: { error: "Email and password are required" }, status: :unprocessable_entity
    end

    user = User.find_by("LOWER(email) = ?", email)

    if user&.authenticate(password)
      render json: {
        message: "Login successful",
        user: { id: user.id, name: user.name, email: user.email }
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end
