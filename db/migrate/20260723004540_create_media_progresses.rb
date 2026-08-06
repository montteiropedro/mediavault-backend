class CreateMediaProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :media_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :media_item, null: false, foreign_key: true
      t.integer :progress_seconds
      t.datetime :last_watched_at

      t.timestamps
    end
  end
end
