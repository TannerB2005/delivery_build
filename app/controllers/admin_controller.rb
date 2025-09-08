 class AdminController < ApplicationController
  before_action :require_admin

  def all_deliveries
    # Admin can see ALL deliveries with full details
    deliveries = Delivery.includes(:user, :items, delivery_locations: :location).all

    deliveries_data = deliveries.map do |delivery|
      {
        id: delivery.id,
        user: {
          id: delivery.user.id,
          name: delivery.user.name,
          email: delivery.user.email,
          admin: delivery.user.admin?
        },
        weight: delivery.weight,
        status: delivery.status,
        destination: delivery.destination,
        created_at: delivery.created_at,
        updated_at: delivery.updated_at,
        items: delivery.items.map do |item|
          {
            id: item.id,
            name: item.name,
            quantity: item.quantity
          }
        end,
        locations: delivery.delivery_locations.map do |dl|
          {
            stop_order: dl.stop_order,
            location: {
              id: dl.location.id,
              address: dl.location.address,
              city: dl.location.city,
              state: dl.location.state,
              zip_code: dl.location.zip_code
            }
          }
        end.sort_by { |loc| loc[:stop_order] }
      }
    end

    render json: {
      message: "Admin access: All deliveries retrieved",
      deliveries: deliveries_data,
      total_count: deliveries.count,
      admin_summary: {
        total_weight: deliveries.sum(:weight),
        status_breakdown: deliveries.group(:status).count,
        deliveries_by_user: deliveries.joins(:user).group("users.name").count,
        admin_users: User.where(admin: true).pluck(:email),
        total_users: User.count,
        admin_users_count: User.where(admin: true).count
      }
    }
  end

  def all_users
    # Admin can see all users with admin status
    users = User.all
    delivery_counts = Delivery.group(:user_id).count

    users_data = users.map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        admin: user.admin?,
        delivery_count: delivery_counts[user.id] || 0,
        created_at: user.created_at,
        updated_at: user.updated_at
      }
    end

    render json: {
      message: "Admin access: All users retrieved",
      users: users_data,
      total_count: users.count,
      admin_count: users.count { |u| u.admin? }
    }
  end

  def promote_user
    user = User.find(params[:user_id])
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
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  def demote_user
    user = User.find(params[:user_id])
    user.remove_admin!

    render json: {
      message: "Admin privileges removed successfully",
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        admin: user.admin?
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  private

  def require_admin
    # For now, we'll check admin status from a simple header
    # In a real app, you'd verify a JWT token or session
    user_id = request.headers["X-User-ID"]
    admin_token = request.headers["X-Admin-Token"]

    if user_id.present?
      user = User.find_by(id: user_id)
      unless user&.admin?
        render json: { error: "Admin access required" }, status: :forbidden
        nil
      end
    elsif admin_token == "admin-secret-token"
      # Allow temporary admin access with secret token for testing
      nil
    else
      render json: {
        error: "Admin access required. Include X-User-ID header with admin user ID or X-Admin-Token header."
      }, status: :forbidden
    end
  end
 end
