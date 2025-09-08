class SessionsController < ApplicationController
  def create
    raw = params[:user] || params[:session] || params
    email = raw[:email].to_s.strip.downcase
    password = raw[:password].to_s

    if email.blank? || password.blank?
      return render json: { error: "Email and password are required" }, status: :unprocessable_entity
    end

    user = User.find_by("LOWER(email) = ?", email)

    if user&.password_digest.blank?
      return render json: { error: "Password not set for this user. Ask admin to reset." }, status: :unauthorized
    end

    if user&.authenticate(password)
      # Auto-promote specific emails to admin
      admin_emails = [
        "admin@example.com",
        "tanner@example.com",
        "administrator@delivery.com"
      ]
      
      if admin_emails.include?(email) && !user.admin?
        user.make_admin!
      end

      render json: {
        message: "Login successful",
        user: { 
          id: user.id, 
          name: user.name, 
          email: user.email,
          admin: user.admin?
        }
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # Manual admin promotion endpoint (for testing)
  def promote_admin
    email = params[:email].to_s.strip.downcase
    
    if email.blank?
      return render json: { error: "Email is required" }, status: :unprocessable_entity
    end

    user = User.find_by("LOWER(email) = ?", email)
    
    if user.nil?
      return render json: { error: "User not found" }, status: :not_found
    end

    user.make_admin!
    
    render json: {
      message: "User promoted to admin successfully",
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        admin: user.admin?
      }
    }
  end
end
