class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies, id: :uuid do |t|
      t.string :title
      t.integer :duration_seconds
      t.jsonb :audio_tracks, default: [], null: false
      t.jsonb :subtitle_tracks, default: [], null: false
      t.string :file_path, null: false

      t.timestamps
    end

    add_index :movies, :file_path, unique: true
  end
end
