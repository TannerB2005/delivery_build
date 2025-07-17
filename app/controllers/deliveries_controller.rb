class DeliveriesController < ApplicationController
    # app/controllers/deliveries_controller.rb
class DeliveriesController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user
      delivery = user.deliveries.build(delivery_params)
      if delivery.save
        render json: delivery, status: :created
      else
        render json: { errors: delivery.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end

  private

  def delivery_params
    params.require(:delivery).permit(:item, :destination)
  end
end

end
