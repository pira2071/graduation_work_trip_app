FactoryBot.define do
  factory :travel_share do
    association :travel
    notification_type { 'itinerary_proposed' }
  end
end
