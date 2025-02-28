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

ActiveRecord::Schema[8.0].define(version: 2025_02_24_203333) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "documents", force: :cascade do |t|
    t.text "file_name"
    t.text "url"
    t.integer "file_size"
    t.text "source"
    t.string "document_status", default: "discovered"
    t.string "classification_status", default: "classification_pending"
    t.string "policy_review_status", default: "policy_pending"
    t.string "recommendation_status", default: "recommendation_pending"
    t.string "status"
    t.string "document_category", default: "Unknown"
    t.float "document_category_confidence"
    t.text "accessibility_recommendation", default: "Unknown"
    t.text "accessibility_action"
    t.datetime "action_taken_on"
    t.text "title"
    t.text "author"
    t.text "subject"
    t.text "keywords"
    t.datetime "creation_date"
    t.datetime "modification_date"
    t.text "producer"
    t.text "pdf_version"
    t.integer "number_of_pages"
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "recommended_category"
    t.float "category_confidence"
    t.string "approved_category"
    t.string "changed_category"
    t.string "recommended_accessibility_action"
    t.float "accessibility_confidence"
    t.string "approved_accessibility_action"
    t.string "changed_accessibility_action"
    t.text "notes"
    t.text "summary"
    t.index ["site_id"], name: "index_documents_on_site_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.string "location"
    t.string "primary_url"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sites_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "documents", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "sites", "users"
end
