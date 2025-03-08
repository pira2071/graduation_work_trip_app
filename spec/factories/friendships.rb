FactoryBot.define do
  factory :friendship do
    association :requester, factory: :user
    association :receiver, factory: :user
    status { 'pending' }

    trait :accepted do
      status { 'accepted' }
      accepted_at { Time.current }
    end

    trait :rejected do
      status { 'rejected' }
      rejected_at { Time.current }
    end
  end
end
