



ActiveRecord::Schema[8.0].define(version: 2025_09_08_223908) do
  create_table "deliveries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.decimal "weight"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "destination"
    t.index ["user_id"], name: "index_deliveries_on_user_id"
  end

  create_table "delivery_locations", force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.integer "location_id", null: false
    t.integer "stop_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_delivery_locations_on_delivery_id"
    t.index ["location_id"], name: "index_delivery_locations_on_location_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.string "name"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_id"], name: "index_items_on_delivery_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.boolean "admin", default: false, null: false
  end

  add_foreign_key "deliveries", "users"
  add_foreign_key "delivery_locations", "deliveries"
  add_foreign_key "delivery_locations", "locations"
  add_foreign_key "items", "deliveries"
end
