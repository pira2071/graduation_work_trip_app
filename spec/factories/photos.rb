FactoryBot.define do
  factory :photo do
    association :travel
    association :user
    day_number { Faker::Number.between(from: 1, to: 5) }
    image { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg'), 'image/jpeg') }
  end
end
