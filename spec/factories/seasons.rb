FactoryBot.define do
  factory :season do
    show
    number { 1 }
    title { "Test Season" }
    sequence(:source_path) { |n| "/path/to/season_#{n}" }
  end
end
