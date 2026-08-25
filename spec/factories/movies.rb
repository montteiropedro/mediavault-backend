FactoryBot.define do
  factory :movie do
    title { "Test Movie" }
    duration_seconds { 1000 }
    audio_tracks { [{ "id" => 0, "language" => "en", "label" => "English" }] }
    subtitle_tracks { [{ "id" => 0, "language" => "en", "label" => "English" }] }
    sequence(:file_path) { |n| "/path/to/movie_#{n}.mkv" }
  end
end
