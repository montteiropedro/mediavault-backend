class AddAuthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :name, :nickname

    add_column :users, :username, :string, null: false
    add_column :users, :token_digest, :string, null: false

    add_index :users, :username, unique: true
    add_index :users, :token_digest, unique: true
  end
end
