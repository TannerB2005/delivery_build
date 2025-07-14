class DeliveryLocation < ApplicationRecord
  belongs_to :delivery
  belongs_to :location
end
