class AddDestinationToDeliveries < ActiveRecord::Migration[8.0]
  def change
    add_column :deliveries, :destination, :string
  end
end
