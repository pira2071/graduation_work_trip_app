FactoryBot.define do
  factory :packing_list do
    name { Faker::Lorem.words(number: 2).join(' ') }
    association :user

    trait :with_items do
      transient do
        items_count { 5 }
      end

      after(:create) do |packing_list, evaluator|
        create_list(:packing_item, evaluator.items_count, packing_list: packing_list)
      end
    end
  end
end
