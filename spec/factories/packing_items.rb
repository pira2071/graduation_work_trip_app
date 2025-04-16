FactoryBot.define do
  factory :packing_item do
    name { Faker::Lorem.word }
    association :packing_list
    checked { false }

    trait :checked do
      checked { true }
    end
  end
end
