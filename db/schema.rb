# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_25_195251) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.string "record_type"
    t.uuid "fileset_uuid"
    t.uuid "record_id"
    t.uuid "blob_id", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
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

  create_table "batch_ingest_files", force: :cascade do |t|
    t.string "google_file_name", null: false
    t.string "google_file_id", null: false
    t.bigint "batch_ingest_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["batch_ingest_id"], name: "index_batch_ingest_files_on_batch_ingest_id"
  end

  create_table "batch_ingests", force: :cascade do |t|
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.string "access_token", null: false
    t.string "refresh_token"
    t.string "expires_in"
    t.string "issued_at"
    t.string "error_message"
    t.string "google_spreadsheet_name", null: false
    t.string "google_spreadsheet_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["title"], name: "index_batch_ingests_on_title", unique: true
    t.index ["user_id"], name: "index_batch_ingests_on_user_id"
  end

  create_table "collections", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested"
    t.string "title", null: false
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
    t.string "title", null: false
    t.string "fedora3_uuid"
    t.string "depositor"
    t.text "description"
    t.json "creators", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_communities_on_owner_id"
  end

  create_table "digitization_batch_metadata_ingests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.string "error_message"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_digitization_batch_metadata_ingests_on_user_id"
  end

  create_table "digitization_books", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "peel_id"
    t.integer "run"
    t.integer "part_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "dates_issued", array: true
    t.string "temporal_subjects", array: true
    t.string "title", null: false
    t.text "alternative_titles", array: true
    t.string "resource_type", null: false
    t.string "genres", null: false, array: true
    t.string "languages", null: false, array: true
    t.string "publishers", array: true
    t.string "places_of_publication", array: true
    t.string "extent"
    t.text "notes", array: true
    t.string "geographic_subjects", array: true
    t.string "rights"
    t.string "topical_subjects", array: true
    t.string "volume_label"
    t.datetime "date_ingested", null: false
    t.datetime "record_created_at"
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.uuid "digitization_batch_metadata_ingest_id"
    t.bigint "logo_id"
    t.index ["digitization_batch_metadata_ingest_id"], name: "index_digitization_books_on_batch_metadata_ingest_id"
    t.index ["logo_id"], name: "index_digitization_books_on_logo_id"
    t.index ["owner_id"], name: "index_digitization_books_on_owner_id"
    t.index ["peel_id", "run", "part_number"], name: "unique_peel_book", unique: true
  end

  create_table "digitization_fulltexts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "digitization_book_id", null: false
    t.text "text", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["digitization_book_id"], name: "index_digitization_fulltexts_on_digitization_book_id"
  end

  create_table "digitization_images", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "peel_image_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "date_ingested", null: false
    t.datetime "record_created_at"
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.string "title", null: false
    t.index ["owner_id"], name: "index_digitization_images_on_owner_id"
    t.index ["peel_image_id"], name: "unique_peel_image", unique: true
  end

  create_table "digitization_maps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "peel_map_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "date_ingested", null: false
    t.datetime "record_created_at"
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.string "title", null: false
    t.index ["owner_id"], name: "index_digitization_maps_on_owner_id"
    t.index ["peel_map_id"], name: "unique_peel_map", unique: true
  end

  create_table "digitization_newspapers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "publication_code"
    t.string "year"
    t.string "month"
    t.string "day"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "date_ingested", null: false
    t.datetime "record_created_at"
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.string "title", null: false
    t.index ["owner_id"], name: "index_digitization_newspapers_on_owner_id"
    t.index ["publication_code", "year", "month", "day"], name: "unique_peel_newspaper", unique: true
  end

  create_table "draft_items", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid "uuid"
    t.integer "status", default: 0, null: false
    t.integer "wizard_step", default: 0, null: false
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
    t.uuid "thumbnail_id"
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
    t.uuid "thumbnail_id"
    t.index ["id"], name: "index_draft_theses_on_id", unique: true
    t.index ["institution_id"], name: "index_draft_theses_on_institution_id"
    t.index ["language_id"], name: "index_draft_theses_on_language_id"
    t.index ["user_id"], name: "index_draft_theses_on_user_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uid", null: false
    t.string "provider", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider", unique: true
    t.index ["user_id", "provider"], name: "index_identities_on_user_id_and_provider", unique: true
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
    t.datetime "date_ingested", null: false
    t.string "title", null: false
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
    t.json "member_of_paths", null: false, array: true
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
    t.json "subject", array: true
    t.bigint "batch_ingest_id"
    t.index ["batch_ingest_id"], name: "index_items_on_batch_ingest_id"
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

  create_table "read_only_modes", force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
  end

  create_table "theses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "visibility"
    t.bigint "owner_id", null: false
    t.datetime "record_created_at"
    t.string "hydra_noid"
    t.datetime "date_ingested", null: false
    t.string "title", null: false
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
    t.json "member_of_paths", null: false, array: true
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
    t.json "subject", array: true
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
    t.string "api_key_digest"
    t.boolean "system", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.uuid "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "announcements", "users"
  add_foreign_key "batch_ingest_files", "batch_ingests"
  add_foreign_key "batch_ingests", "users"
  add_foreign_key "collections", "users", column: "owner_id"
  add_foreign_key "communities", "users", column: "owner_id"
  add_foreign_key "digitization_batch_metadata_ingests", "users"
  add_foreign_key "digitization_books", "active_storage_attachments", column: "logo_id", on_delete: :nullify
  add_foreign_key "digitization_books", "digitization_batch_metadata_ingests"
  add_foreign_key "digitization_books", "users", column: "owner_id"
  add_foreign_key "digitization_fulltexts", "digitization_books"
  add_foreign_key "digitization_images", "users", column: "owner_id"
  add_foreign_key "digitization_maps", "users", column: "owner_id"
  add_foreign_key "digitization_newspapers", "users", column: "owner_id"
  add_foreign_key "draft_items", "users"
  add_foreign_key "draft_theses", "institutions"
  add_foreign_key "draft_theses", "languages"
  add_foreign_key "draft_theses", "users"
  add_foreign_key "items", "batch_ingests"
  add_foreign_key "items", "users", column: "owner_id"
  add_foreign_key "theses", "users", column: "owner_id"
end
