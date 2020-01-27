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

ActiveRecord::Schema.define(version: 2020_01_22_171348) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name"
    t.bigint "blob_id", null: false
    t.datetime "created_at"
    t.string "record_type"
    t.uuid "fileset_uuid"
    t.uuid "record_id"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
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
    t.bigint "logo_id"
  end

  create_table "collections", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested"
    t.string "title"
    t.string "fedora3_uuid"
    t.string "depositor"
    t.uuid "community_id"
    t.text "description"
    t.json "creators", array: true
    t.boolean "restricted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_collections_on_owner_id"
  end

  create_table "communities", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested"
    t.string "title"
    t.string "fedora3_uuid"
    t.string "depositor"
    t.text "description"
    t.json "creators", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_communities_on_owner_id"
  end

  create_table "draft_items", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
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
    t.boolean "is_published_in_era", default: false
    t.index ["id"], name: "index_draft_items_on_id", unique: true
    t.index ["type_id"], name: "index_draft_items_on_type_id"
    t.index ["user_id"], name: "index_draft_items_on_user_id"
  end

  create_table "draft_items_languages", force: :cascade do |t|
    t.bigint "language_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "draft_item_id"
    t.index ["draft_item_id"], name: "index_draft_items_languages_on_draft_item_id"
    t.index ["language_id"], name: "index_draft_items_languages_on_language_id"
  end

  create_table "draft_theses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "uuid"
    t.integer "status", default: 0, null: false
    t.integer "wizard_step", default: 0, null: false
    t.bigint "user_id", null: false
    t.integer "thumbnail_id"
    t.string "title"
    t.string "alternate_title"
    t.string "creator"
    t.text "description"
    t.string "degree"
    t.string "degree_level"
    t.string "specialization"
    t.string "graduation_term"
    t.integer "graduation_year"
    t.bigint "language_id"
    t.bigint "institution_id"
    t.datetime "date_accepted"
    t.datetime "date_submitted"
    t.text "rights"
    t.integer "visibility", default: 0, null: false
    t.datetime "embargo_end_date"
    t.json "member_of_paths"
    t.json "subjects", array: true
    t.json "supervisors", array: true
    t.json "departments", array: true
    t.json "committee_members", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_published_in_era", default: false
    t.index ["id"], name: "index_draft_theses_on_id", unique: true
    t.index ["institution_id"], name: "index_draft_theses_on_institution_id"
    t.index ["language_id"], name: "index_draft_theses_on_language_id"
    t.index ["user_id"], name: "index_draft_theses_on_user_id"
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

  create_table "institutions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_doi_states", force: :cascade do |t|
    t.uuid "item_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested"
    t.string "title"
    t.string "fedora3_uuid"
    t.string "depositor"
    t.string "alternative_title"
    t.string "doi"
    t.datetime "embargo_end_date"
    t.string "visibility_after_embargo"
    t.string "fedora3_handle"
    t.string "ingest_batch"
    t.string "northern_north_america_filename"
    t.string "northern_north_america_item_id"
    t.text "rights"
    t.integer "sort_year"
    t.json "embargo_history", array: true
    t.json "is_version_of", array: true
    t.json "member_of_paths", array: true
    t.json "subject", array: true
    t.json "creators", array: true
    t.json "contributors", array: true
    t.string "created"
    t.json "temporal_subjects", array: true
    t.json "spatial_subjects", array: true
    t.text "description"
    t.string "publisher"
    t.json "languages", array: true
    t.text "license"
    t.string "item_type"
    t.string "source"
    t.string "related_link"
    t.json "publication_status", array: true
    t.bigint "logo_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logo_id"], name: "index_items_on_logo_id"
    t.index ["owner_id"], name: "index_items_on_owner_id"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rdf_annotations", force: :cascade do |t|
    t.string "table"
    t.string "column"
    t.string "predicate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "theses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested"
    t.string "title"
    t.string "fedora3_uuid"
    t.string "depositor"
    t.string "alternative_title"
    t.string "doi"
    t.datetime "embargo_end_date"
    t.string "visibility_after_embargo"
    t.string "fedora3_handle"
    t.string "ingest_batch"
    t.string "northern_north_america_filename"
    t.string "northern_north_america_item_id"
    t.text "rights"
    t.integer "sort_year"
    t.json "embargo_history", array: true
    t.json "is_version_of", array: true
    t.json "member_of_paths", array: true
    t.json "subject", array: true
    t.text "abstract"
    t.string "language"
    t.datetime "date_accepted"
    t.datetime "date_submitted"
    t.string "degree"
    t.string "institution"
    t.string "dissertant"
    t.string "graduation_date"
    t.string "thesis_level"
    t.string "proquest"
    t.string "unicorn"
    t.string "specialization"
    t.json "departments", array: true
    t.json "supervisors", array: true
    t.json "committee_members", array: true
    t.bigint "logo_id"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["logo_id"], name: "index_theses_on_logo_id"
    t.index ["owner_id"], name: "index_theses_on_owner_id"
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
  add_foreign_key "collections", "users", column: "owner_id"
  add_foreign_key "communities", "users", column: "owner_id"
  add_foreign_key "draft_items", "users"
  add_foreign_key "draft_theses", "institutions"
  add_foreign_key "draft_theses", "languages"
  add_foreign_key "draft_theses", "users"
  add_foreign_key "items", "active_storage_attachments", column: "logo_id", on_delete: :nullify
  add_foreign_key "items", "users", column: "owner_id"
  add_foreign_key "theses", "active_storage_attachments", column: "logo_id", on_delete: :nullify
  add_foreign_key "theses", "users", column: "owner_id"
end
