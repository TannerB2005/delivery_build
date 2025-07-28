class DeliveriesController < ApplicationController
  before_action :set_delivery, only: [:show, :update, :destroy]

  # GET /deliveries
  def index
    deliveries = Delivery.includes(:user).all
    render json: deliveries.to_json(include: :user), status: :ok
  end

  # GET /deliveries/:id
  def show
    render json: @delivery.to_json(include: :user), status: :ok
  end

  # POST /deliveries
  def create
    user = User.find_by(email: params[:email])

    if user.nil?
      render json: { error: "User not found with provided email" }, status: :not_found
      return
    end

    delivery = user.deliveries.build(delivery_params)

    if delivery.save
      render json: delivery.to_json(include: :user), status: :created
    else
      render json: { errors: delivery.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /deliveries/:id
  def update
    if @delivery.update(delivery_params)
      render json: @delivery.to_json(include: :user), status: :ok
    else
      render json: { errors: @delivery.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /deliveries/:id
  def destroy
    @delivery.destroy
    head :no_content
  end

  private

  def set_delivery
    @delivery = Delivery.find_by(id: params[:id])
    render json: { error: "Delivery not found" }, status: :not_found unless @delivery
  end

  def delivery_params
    params.require(:delivery).permit(:item, :weight, :location)
  end
end
