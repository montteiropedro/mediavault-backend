class AddCodecNameToMoviesAndEpisodes < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :codec_name, :string
    add_column :episodes, :codec_name, :string
  end
end
