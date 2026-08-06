class CreateMediaItems < ActiveRecord::Migration[8.1]
  def change
    create_table :media_items do |t|
      t.string :title
      t.text :description
      t.integer :duration
      t.integer :media_type
      t.string :file_path, null: false
      t.references :category, foreign_key: true
      t.jsonb :metadata

      t.timestamps
    end

    add_index :media_items, :file_path, unique: true
  end
end
