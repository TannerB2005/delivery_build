class User < ApplicationRecord
    has_many :deliveries
    validates :name, presence: true
    validates :email, presence: true, uniqueness: true
end
