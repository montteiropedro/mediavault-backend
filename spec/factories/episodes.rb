FactoryBot.define do
  factory :episode do
    season
    number { 1 }
    title { "Test Episode" }
    duration_seconds { 1000 }
    audio_tracks { [{ "id" => 0, "language" => "en", "label" => "English" }] }
    subtitle_tracks { [{ "id" => 0, "language" => "en", "label" => "English" }] }
    sequence(:file_path) { |n| "/path/to/episode_#{n}.mkv" }
  end
end
