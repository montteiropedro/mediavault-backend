class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons, id: :uuid do |t|
      t.references :show, null: false, foreign_key: true, type: :uuid
      t.integer :number, null: false
      t.string :title
      t.string :source_path, null: false

      t.timestamps
    end

    add_index :seasons, [:show_id, :number], unique: true
    add_index :seasons, :source_path, unique: true
  end
end
