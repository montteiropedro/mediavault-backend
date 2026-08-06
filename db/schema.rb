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

ActiveRecord::Schema[8.1].define(version: 2026_07_23_004551) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.bigint "media_item_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
    t.index ["media_item_id"], name: "index_collection_items_on_media_item_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_private"
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "media_items", force: :cascade do |t|
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration"
    t.string "file_path", null: false
    t.integer "media_type"
    t.jsonb "metadata"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_media_items_on_category_id"
    t.index ["file_path"], name: "index_media_items_on_file_path", unique: true
  end

  create_table "media_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_watched_at"
    t.bigint "media_item_id", null: false
    t.integer "progress_seconds"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["media_item_id"], name: "index_media_progresses_on_media_item_id"
    t.index ["user_id"], name: "index_media_progresses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "collection_items", "collections"
  add_foreign_key "collection_items", "media_items"
  add_foreign_key "collections", "users"
  add_foreign_key "media_items", "categories"
  add_foreign_key "media_progresses", "media_items"
  add_foreign_key "media_progresses", "users"
end
