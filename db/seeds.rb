require 'faker'

User.destroy_all
Delivery.destroy_all

#create users
users = []
5.times do
users << User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.email
)
end


