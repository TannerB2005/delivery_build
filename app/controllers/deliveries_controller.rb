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
        deliveries_by_user: deliveries.joins(:user).group("users.name").count
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
    render json: { error: "User not found" }, status: :not_found
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
    # Allow both nested { delivery: {...} } and flat payloads.
    raw_delivery = params[:delivery] || params

    # Normalize to plain hash with symbol keys (handles ActionController::Parameters, string keys, mixed keys)
    raw_hash = if raw_delivery.respond_to?(:to_unsafe_h)
                 raw_delivery.to_unsafe_h
    else
                 raw_delivery.to_h rescue {}
    end
    normalized = raw_hash.deep_transform_keys { |k| k.to_s.underscore.to_sym }

    # Extract legacy single item name (supports :item or 'item')
    legacy_item_name = normalized.delete(:item) || normalized.delete("item")

    # Pull out nested arrays before strong params (we'll whitelist manually)
    items_payload      = normalized.delete(:items)      || []
    locations_payload  = normalized.delete(:locations)  || []

    # Build attributes via strong params when nested; fallback to normalized for flat usage
    delivery_attrs = if params[:delivery].present?
                       delivery_params.to_h
    else
                       normalized.slice(:user_id, :weight, :status, :destination)
    end
    delivery_attrs[:status] = (delivery_attrs[:status].presence || "pending")

    delivery = Delivery.new(delivery_attrs)

    ActiveRecord::Base.transaction do
      if delivery.save
        # Legacy single item param
        if legacy_item_name.present?
          delivery.items.create!(name: legacy_item_name, quantity: 1)
        end

        # Items array (each element may have string or symbol keys)
        Array(items_payload).each do |item_hash|
          next if item_hash.blank?
          name = item_hash[:name] || item_hash["name"]
          quantity = item_hash[:quantity] || item_hash["quantity"] || 1
          next if name.blank?
            delivery.items.create!(name: name, quantity: quantity)
        end

        # Locations array
        Array(locations_payload).each_with_index do |loc_hash, idx|
          next if loc_hash.blank?
          address  = loc_hash[:address]  || loc_hash["address"]
          city     = loc_hash[:city]     || loc_hash["city"]
          state    = loc_hash[:state]    || loc_hash["state"]
          zip_code = loc_hash[:zip_code] || loc_hash["zip_code"]
          next if address.blank? || city.blank?

          location = Location.find_or_create_by(
            address: address,
            city: city,
            state: state,
            zip_code: zip_code
          )

          delivery.delivery_locations.create!(location: location, stop_order: idx + 1)
        end

        delivery.reload
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
          items: delivery.items.map { |item| { id: item.id, name: item.name, quantity: item.quantity } },
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

        render json: { delivery: delivery_data, message: "Delivery created successfully" }, status: :created
      else
        render json: { errors: delivery.errors.full_messages, message: "Failed to create delivery" }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: [ e.message ], message: "Failed to create delivery" }, status: :unprocessable_entity
  end

  def update
    delivery = Delivery.find(params[:id])

    if delivery.update(delivery_params)
      # Return the same format as show for consistency
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
        message: "Delivery updated successfully"
      }
    else
      render json: {
        errors: delivery.errors.full_messages,
        message: "Failed to update delivery"
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Delivery not found" }, status: :not_found
  end

  def destroy
    delivery = Delivery.find(params[:id])

    if delivery.destroy
      render json: { message: "Delivery deleted successfully" }
    else
      render json: {
        errors: delivery.errors.full_messages,
        message: "Failed to delete delivery"
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Delivery not found" }, status: :not_found
  end

  def analytics
    deliveries = Delivery.includes(:user, :items)

    analytics_data = {
      total_deliveries: deliveries.count,
      total_weight: deliveries.sum(:weight),
      average_weight: deliveries.average(:weight)&.round(2),
      status_distribution: deliveries.group(:status).count,
      deliveries_by_user: deliveries.joins(:user).group("users.name").count,
      deliveries_by_date: deliveries.group_by_day(:created_at).count,
      top_destinations: deliveries.group(:destination).count.sort_by { |k, v| -v }.first(5).to_h,
      weight_ranges: {
        light: deliveries.where("weight < 10").count,
        medium: deliveries.where("weight >= 10 AND weight < 50").count,
        heavy: deliveries.where("weight >= 50").count
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
