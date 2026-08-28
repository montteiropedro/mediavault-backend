FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "test_user_#{n}" }

    trait :with_progresses do
      after(:create) do |user|
        create_list(:progress, 2, user: user)
      end
    end
  end
end
