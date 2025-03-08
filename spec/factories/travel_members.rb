FactoryBot.define do
  factory :travel_member do
    association :travel
    association :user
    role { :guest }
    
    trait :organizer do
      role { :organizer }
    end
  end
end
