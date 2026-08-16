class SplitMediaItemsMetadataIntoAudioAndSubtitleTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :media_items, :audio_tracks, :jsonb, default: [], null: false
    add_column :media_items, :subtitle_tracks, :jsonb, default: [], null: false
    remove_column :media_items, :metadata, :jsonb
  end
end
