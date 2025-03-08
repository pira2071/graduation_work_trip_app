FactoryBot.define do
  factory :travel do
    title { Faker::Lorem.sentence(word_count: 3) }
    start_date { Date.current }
    end_date { Date.current + 3.days }
    association :user

    trait :with_thumbnail do
      thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg') }
    end

    trait :with_members do
      transient do
        members_count { 2 }
      end

      after(:create) do |travel, evaluator|
        create(:travel_member, travel: travel, user: travel.user, role: :organizer)
        create_list(:travel_member, evaluator.members_count, travel: travel, role: :guest)
      end
    end
  end
end
