FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :notifiable, factory: :friendship
    action { 'friend_request' }
    read_at { nil }
  end
end
