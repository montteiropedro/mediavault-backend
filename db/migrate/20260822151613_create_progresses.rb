class CreateProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :progresses, id: :uuid do |t|
      t.integer :seconds
      t.datetime :last_watched_at
      t.references :playable, polymorphic: true, null: false, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :progresses, [:user_id, :playable_type, :playable_id], unique: true
  end
end
