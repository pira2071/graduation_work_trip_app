FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :notifiable, factory: :friendship
    action { 'friend_request' }
    read { false }
    
    trait :read do
      read { true }
      read_at { Time.current }
    end
    
    trait :travel_notification do
      association :notifiable, factory: :travel
      action { 'itinerary_proposed' }
    end
    
    trait :review_notification do
      association :notifiable, factory: :travel
      action { 'review_submitted' }
    end
  end
end
