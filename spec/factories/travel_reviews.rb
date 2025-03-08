FactoryBot.define do
  factory :travel_review do
    association :travel
    association :user
    content { Faker::Lorem.paragraph }
  end
end
