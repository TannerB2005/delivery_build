class CreateDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :deliveries do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :weight
      t.string :status

      t.timestamps
    end
  end
end
