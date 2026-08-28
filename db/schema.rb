# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_27_171131) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "episodes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "audio_tracks", default: [], null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.string "file_path", null: false
    t.integer "number"
    t.uuid "season_id", null: false
    t.jsonb "subtitle_tracks", default: [], null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["file_path"], name: "index_episodes_on_file_path", unique: true
    t.index ["season_id", "number"], name: "index_episodes_on_season_id_and_number", unique: true
    t.index ["season_id"], name: "index_episodes_on_season_id"
  end

  create_table "movies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "audio_tracks", default: [], null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.string "file_path", null: false
    t.jsonb "subtitle_tracks", default: [], null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["file_path"], name: "index_movies_on_file_path", unique: true
  end

  create_table "progresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_watched_at"
    t.uuid "playable_id", null: false
    t.string "playable_type", null: false
    t.integer "seconds"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["playable_type", "playable_id"], name: "index_progresses_on_playable"
    t.index ["user_id", "playable_type", "playable_id"], name: "index_progresses_on_user_id_and_playable_type_and_playable_id", unique: true
    t.index ["user_id"], name: "index_progresses_on_user_id"
  end

  create_table "seasons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.uuid "show_id", null: false
    t.string "source_path", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["show_id", "number"], name: "index_seasons_on_show_id_and_number", unique: true
    t.index ["show_id"], name: "index_seasons_on_show_id"
    t.index ["source_path"], name: "index_seasons_on_source_path", unique: true
  end

  create_table "shows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "source_path", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["source_path"], name: "index_shows_on_source_path", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nickname"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["token_digest"], name: "index_users_on_token_digest", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "episodes", "seasons"
  add_foreign_key "progresses", "users"
  add_foreign_key "seasons", "shows"
end
