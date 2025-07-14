class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.references :delivery, null: false, foreign_key: true
      t.string :name
      t.integer :quantity

      t.timestamps
    end
  end
end
