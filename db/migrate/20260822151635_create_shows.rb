class CreateShows < ActiveRecord::Migration[8.1]
  def change
    create_table :shows, id: :uuid do |t|
      t.string :title, null: false
      t.string :source_path, null: false

      t.timestamps
    end

    add_index :shows, :source_path, unique: true
  end
end
