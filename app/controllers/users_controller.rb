class UsersController < ApplicationController
  def index
    users = User.all
    # Efficient query for delivery counts
    delivery_counts = Delivery.group(:user_id).count
    # For frontend dropdowns, we don't need delivery data - just user info
    users_data = users.map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        delivery_count: delivery_counts[user.id] || 0
      }
    end
    
    render json: {
      users: users_data,
      total_count: users.count
    }
  end

  def show
    user = User.includes(:deliveries).find(params[:id])
    
    user_data = {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at,
      deliveries: user.deliveries.map do |delivery|
        {
          id: delivery.id,
          weight: delivery.weight,
          status: delivery.status,
          destination: delivery.destination,
          created_at: delivery.created_at
        }
      end,
      statistics: {
        total_deliveries: user.deliveries.count,
        total_weight: user.deliveries.sum(:weight),
        status_breakdown: user.deliveries.group(:status).count
      }
    }
    
    render json: user_data
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def create
    user = User.new(user_params)

    if user.save
      render json: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at
        },
        message: 'User created successfully'
      }, status: :created
    else
      render json: { 
        errors: user.errors.full_messages,
        message: 'Failed to create user'
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
