FactoryBot.define do
  factory :progress do
    user
    playable factory: :movie
    seconds { 100 }
    last_watched_at { Time.current }

    trait :for_episode do
      playable factory: :episode
    end
  end
end
