FactoryBot.define do
  factory :show do
    title { "Test Show" }
    sequence(:source_path) { |n| "/path/to/show_#{n}" }
  end
end
