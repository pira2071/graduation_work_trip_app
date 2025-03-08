FactoryBot.define do
  factory :schedule do
    association :spot
    day_number { Faker::Number.between(from: 1, to: 5) }
    time_zone { Schedule.time_zones.keys.sample }
    sequence(:order_number) { |n| n }
  end
end
