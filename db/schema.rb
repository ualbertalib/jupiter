# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_04_30_213954) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name"
    t.string "record_gid"
    t.bigint "blob_id", null: false
    t.datetime "created_at"
    t.bigint "record_id"
    t.string "record_type"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_gid", "blob_id"], name: "index_active_storage_attachments_on_record_gid_and_blob_id", unique: true
    t.index ["record_gid", "name"], name: "index_active_storage_attachments_on_record_gid_and_name"
    t.index ["record_gid"], name: "index_active_storage_attachments_on_record_gid"
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key"
    t.string "filename"
    t.string "content_type"
    t.text "metadata"
    t.integer "byte_size"
    t.string "checksum"
    t.datetime "created_at"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.text "message", null: false
    t.bigint "user_id", null: false
    t.datetime "removed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_announcements_on_user_id"
  end

  create_table "attachment_shims", force: :cascade do |t|
    t.string "owner_global_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "draft_items", force: :cascade do |t|
    t.uuid "uuid"
    t.integer "status", default: 0, null: false
    t.integer "wizard_step", default: 0, null: false
    t.integer "thumbnail_id"
    t.string "title"
    t.string "alternate_title"
    t.date "date_created"
    t.text "description"
    t.string "source"
    t.string "related_item"
    t.integer "license", default: 0, null: false
    t.text "license_text_area"
    t.integer "visibility", default: 0, null: false
    t.datetime "embargo_end_date"
    t.integer "visibility_after_embargo", default: 0, null: false
    t.bigint "type_id"
    t.bigint "user_id", null: false
    t.json "creators", array: true
    t.json "subjects", array: true
    t.json "member_of_paths"
    t.json "contributors", array: true
    t.json "places", array: true
    t.json "time_periods", array: true
    t.json "citations", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type_id"], name: "index_draft_items_on_type_id"
    t.index ["user_id"], name: "index_draft_items_on_user_id"
  end

  create_table "draft_items_languages", force: :cascade do |t|
    t.bigint "draft_item_id"
    t.bigint "language_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_item_id"], name: "index_draft_items_languages_on_draft_item_id"
    t.index ["language_id"], name: "index_draft_items_languages_on_language_id"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uid", null: false
    t.string "provider", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "item_doi_states", force: :cascade do |t|
    t.uuid "item_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.boolean "admin", default: false, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "suspended", default: false, null: false
    t.datetime "previous_sign_in_at"
    t.string "previous_sign_in_ip"
    t.datetime "last_seen_at"
    t.string "last_seen_ip"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "announcements", "users"
  add_foreign_key "draft_items", "users"
end
