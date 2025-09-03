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

ActiveRecord::Schema[7.1].define(version: 2025_09_03_023230) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "card_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_assignments_on_card_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "exercice_id", null: false
    t.boolean "succeeded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercice_id"], name: "index_attempts_on_exercice_id"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "title"
    t.string "discord_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discord_server_id"
    t.string "discord_invite_url"
  end

  create_table "cards", force: :cascade do |t|
    t.bigint "list_id", null: false
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "drive_link"
    t.datetime "begin_at"
    t.datetime "end_at"
    t.integer "position"
    t.index ["list_id"], name: "index_cards_on_list_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name"
    t.string "github_link"
    t.string "slides_link"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ticket_activation"
  end

  create_table "exercices", force: :cascade do |t|
    t.string "name"
    t.string "cw_token"
    t.integer "position"
    t.bigint "course_id", null: false
    t.boolean "visible"
    t.integer "kata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.boolean "optional"
    t.string "colab_link"
    t.index ["course_id"], name: "index_exercices_on_course_id"
  end

  create_table "lists", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "position"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_lists_on_team_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_messages_on_team_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "subject"
    t.string "drive_link"
    t.integer "max_booking"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active"
    t.string "color"
    t.bigint "batch_id", null: false
    t.index ["batch_id"], name: "index_projects_on_batch_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_ratings_on_project_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "supervisions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_supervisions_on_project_id"
    t.index ["user_id"], name: "index_supervisions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "progress", default: 0
    t.string "drive_link"
    t.string "trello_link"
    t.datetime "meeting_date"
    t.string "meeting_place"
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_teams_on_project_id"
    t.index ["user_id"], name: "index_teams_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "content"
    t.integer "progress", default: 0
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_tickets_on_course_id"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin"
    t.string "first_name"
    t.string "last_name"
    t.string "student_number"
    t.integer "progress", default: 0
    t.boolean "teacher"
    t.bigint "team_id"
    t.string "avatar_color"
    t.string "cw_nickname"
    t.datetime "reading_date"
    t.boolean "reading"
    t.string "exam_nickname"
    t.bigint "batch_id", null: false
    t.boolean "drop", default: false
    t.index ["batch_id"], name: "index_users_on_batch_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "cards"
  add_foreign_key "assignments", "users"
  add_foreign_key "attempts", "exercices"
  add_foreign_key "attempts", "users"
  add_foreign_key "cards", "lists"
  add_foreign_key "exercices", "courses"
  add_foreign_key "lists", "teams"
  add_foreign_key "messages", "teams"
  add_foreign_key "messages", "users"
  add_foreign_key "projects", "batches"
  add_foreign_key "ratings", "projects"
  add_foreign_key "ratings", "users"
  add_foreign_key "supervisions", "projects"
  add_foreign_key "supervisions", "users"
  add_foreign_key "teams", "projects"
  add_foreign_key "teams", "users"
  add_foreign_key "tickets", "courses"
  add_foreign_key "tickets", "users"
  add_foreign_key "users", "batches"
  add_foreign_key "users", "teams"
end
