class DeliveriesController < ApplicationController
  def index
    # Filter by user_id if provided
    deliveries = Delivery.includes(:user, :items, delivery_locations: :location)
    deliveries = deliveries.where(user_id: params[:user_id]) if params[:user_id].present?
    deliveries = deliveries.all
    # Enhanced JSON structure for better visualization
    deliveries_data = deliveries.map do |delivery|
      {
        id: delivery.id,
        user: {
          id: delivery.user.id,
          name: delivery.user.name,
          email: delivery.user.email
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
      deliveries: deliveries_data,
      total_count: deliveries.count,
      summary: {
        total_weight: deliveries.sum(:weight),
        status_breakdown: deliveries.group(:status).count,
        deliveries_by_user: deliveries.joins(:user).group('users.name').count
      }
    }
  end

  def by_user
    user = User.find(params[:user_id])
    deliveries = user.deliveries.includes(:user, :items, delivery_locations: :location)
    
    # Enhanced JSON structure for better visualization
    deliveries_data = deliveries.map do |delivery|
      {
        id: delivery.id,
        user: {
          id: delivery.user.id,
          name: delivery.user.name,
          email: delivery.user.email
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
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      },
      deliveries: deliveries_data,
      total_count: deliveries.count,
      summary: {
        total_weight: deliveries.sum(:weight),
        status_breakdown: deliveries.group(:status).count
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def show
    delivery = Delivery.includes(:user, :items, delivery_locations: :location).find(params[:id])
    
    delivery_data = {
      id: delivery.id,
      user: {
        id: delivery.user.id,
        name: delivery.user.name,
        email: delivery.user.email
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
      locations: delivery.delivery_locations.includes(:location).order(:stop_order).map do |dl|
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
      end
    }
    
    render json: delivery_data
  end

  def create
    # Extract item from params before creating delivery
    item_name = params[:delivery].delete(:item)
    
    # Set default status if not provided
    delivery_attrs = delivery_params
    delivery_attrs[:status] ||= "pending"
    
    delivery = Delivery.new(delivery_attrs)

    # Use a database transaction to ensure data consistency
    ActiveRecord::Base.transaction do
      if delivery.save
        # Handle legacy single item parameter (for backward compatibility)
        if item_name.present?
          delivery.items.create!(
            name: item_name,
            quantity: 1
          )
        end

        # Create associated items if provided (new format)
        if params[:delivery][:items].present?
          params[:delivery][:items].each do |item_params|
            delivery.items.create!(
              name: item_params[:name],
              quantity: item_params[:quantity]
            )
          end
        end

        # Create delivery locations if provided
        if params[:delivery][:locations].present?
          params[:delivery][:locations].each_with_index do |location_params, index|
            # Find or create the location
            location = Location.find_or_create_by(
              address: location_params[:address],
              city: location_params[:city],
              state: location_params[:state],
              zip_code: location_params[:zip_code]
            )

            # Create the delivery location with stop order
            delivery.delivery_locations.create!(
              location: location,
              stop_order: index + 1
            )
          end
        end

        # Return the same rich data structure as show endpoint
        delivery.reload # Reload to get associated data
        delivery_data = {
          id: delivery.id,
          user: {
            id: delivery.user.id,
            name: delivery.user.name,
            email: delivery.user.email
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
          locations: delivery.delivery_locations.includes(:location).order(:stop_order).map do |dl|
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
          end
        }

        render json: { 
          delivery: delivery_data,
          message: 'Delivery created successfully'
        }, status: :created
      else
        render json: { 
          errors: delivery.errors.full_messages,
          message: 'Failed to create delivery'
        }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { 
      errors: [e.message],
      message: 'Failed to create delivery'
    }, status: :unprocessable_entity
  end

  def analytics
    deliveries = Delivery.includes(:user, :items)
    
    analytics_data = {
      total_deliveries: deliveries.count,
      total_weight: deliveries.sum(:weight),
      average_weight: deliveries.average(:weight)&.round(2),
      status_distribution: deliveries.group(:status).count,
      deliveries_by_user: deliveries.joins(:user).group('users.name').count,
      deliveries_by_date: deliveries.group_by_day(:created_at).count,
      top_destinations: deliveries.group(:destination).count.sort_by { |k, v| -v }.first(5).to_h,
      weight_ranges: {
        light: deliveries.where('weight < 10').count,
        medium: deliveries.where('weight >= 10 AND weight < 50').count,
        heavy: deliveries.where('weight >= 50').count
      }
    }
    
    render json: analytics_data
  end

  private

  def delivery_params
    params.require(:delivery).permit(
      :weight,
      :status,
      :destination,
      :user_id,
      items: [ :name, :quantity ],
      locations: [ :address, :city, :state, :zip_code ]
    )
  end
end
