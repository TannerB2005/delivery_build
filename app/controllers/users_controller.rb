class UsersController < ApplicationController

def index 
  users = User.includes(:deliveries).all
  render json: users.to_json(include: :deliveries)
end

  def create
    user = User.new(user_params)

    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
