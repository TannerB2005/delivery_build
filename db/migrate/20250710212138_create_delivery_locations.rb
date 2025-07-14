class CreateDeliveryLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_locations do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.integer :stop_order

      t.timestamps
    end
  end
end
