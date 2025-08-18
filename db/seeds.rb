require 'faker'

# Clear existing data
puts "Clearing existing data..."
DeliveryLocation.destroy_all
Item.destroy_all
Delivery.destroy_all
Location.destroy_all
User.destroy_all

# Create Users
puts "Creating users..."
users = []
5.times do
  users << User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email,
    password: "password1",
    password_confirmation: "password1"
  )
end

# Create an admin user
User.create!(
  name: "Admin User",
  email: "admin@example.com",
  password: "adminpassword",
  password_confirmation: "adminpassword"
)

puts "Created #{users.count} users"

# Create Locations
puts "Creating locations..."
locations = []
8.times do
  locations << Location.create!(
    address: Faker::Address.street_address,
    city: Faker::Address.city,
    state: Faker::Address.state_abbr,
    zip_code: Faker::Address.zip_code
  )
end
puts "Created #{locations.count} locations"

# Create Deliveries with varied data for better visualization
puts "Creating deliveries..."
delivery_statuses = [ "pending", "in_transit", "delivered", "cancelled" ]
destinations = [
  "Downtown Distribution Center",
  "Suburban Mall",
  "Corporate Office Building",
  "Residential Complex",
  "Warehouse District",
  "Shopping Center",
  "Industrial Park",
  "University Campus"
]

# Create 25 deliveries for good visualization data
25.times do |i|
  delivery = Delivery.create!(
    user: users.sample,
    weight: rand(5.0..75.0).round(1),
    status: delivery_statuses.sample,
    destination: destinations.sample
  )

  # Add 1-4 items per delivery
  item_count = rand(1..4)
  item_names = [
    "Electronics Package", "Clothing Items", "Books", "Home Appliances",
    "Sports Equipment", "Food Items", "Documents", "Furniture",
    "Art Supplies", "Medical Supplies", "Tools", "Toys"
  ]

  item_count.times do
    Item.create!(
      delivery: delivery,
      name: item_names.sample,
      quantity: rand(1..10)
    )
  end

  # Add 1-3 route locations per delivery
  route_locations = locations.sample(rand(1..3))
  route_locations.each_with_index do |location, index|
    DeliveryLocation.create!(
      delivery: delivery,
      location: location,
      stop_order: index + 1
    )
  end
end

puts "Created #{Delivery.count} deliveries with items and routes"

# Print summary
puts "\n=== Database Seeded Successfully ==="
puts "Users: #{User.count}"
puts "Locations: #{Location.count}"
puts "Deliveries: #{Delivery.count}"
puts "Items: #{Item.count}"
puts "Delivery Locations: #{DeliveryLocation.count}"
puts "==================================="

# Print some stats for visualization testing
puts "\nDelivery Statistics for Testing:"
puts "- By Status: #{Delivery.group(:status).count}"
puts "- Weight Distribution:"
puts "  - Light (<10kg): #{Delivery.where('weight < 10').count}"
puts "  - Medium (10-50kg): #{Delivery.where('weight >= 10 AND weight < 50').count}"
puts "  - Heavy (>50kg): #{Delivery.where('weight >= 50').count}"
puts "- By User: #{Delivery.joins(:user).group('users.name').count}"
