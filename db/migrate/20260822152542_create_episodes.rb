class CreateEpisodes < ActiveRecord::Migration[8.1]
  def change
    create_table :episodes, id: :uuid do |t|
      t.references :season, null: false, foreign_key: true, type: :uuid
      t.integer :number
      t.string :title
      t.integer :duration_seconds
      t.jsonb :audio_tracks, default: [], null: false
      t.jsonb :subtitle_tracks, default: [], null: false
      t.string :file_path, null: false

      t.timestamps
    end

    add_index :episodes, [:season_id, :number], unique: true
    add_index :episodes, :file_path, unique: true
  end
end
