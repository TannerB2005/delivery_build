class Delivery < ApplicationRecord
  belongs_to :user
  has_many :items, dependent: :destroy
  has_many :delivery_locations, dependent: :destroy
  has_many :locations, through: :delivery_locations

  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :destination, presence: true
end
