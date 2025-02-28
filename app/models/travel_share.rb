class TravelShare < ApplicationRecord
  belongs_to :travel
  
  validates :travel_id, presence: true
  validates :notification_type, presence: true
end
