FactoryBot.define do
  factory :spot do
    name { Faker::Address.city }
    association :travel
    category { [ :sightseeing, :restaurant, :hotel ].sample }
    lat { Faker::Address.latitude }
    lng { Faker::Address.longitude }
    sequence(:order_number) { |n| n }

    trait :with_schedule do
      after(:create) do |spot|
        create(:schedule, spot: spot)
      end
    end
  end
end
