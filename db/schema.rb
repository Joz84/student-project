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

ActiveRecord::Schema[7.1].define(version: 2026_09_29_120000) do
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

  create_table "attendances", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "lesson_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "declared_by", default: 0, null: false
    t.datetime "declared_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "guest_first_name"
    t.string "guest_last_name"
    t.string "guest_student_number"
    t.index ["lesson_id", "user_id"], name: "index_attendances_on_lesson_id_and_user_id", unique: true
    t.index ["lesson_id"], name: "index_attendances_on_lesson_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "batches", force: :cascade do |t|
    t.string "title"
    t.string "discord_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discord_server_id"
    t.string "discord_invite_url"
  end

  create_table "card_skills", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.bigint "skill_id", null: false
    t.integer "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_card_skills_on_card_id"
    t.index ["skill_id"], name: "index_card_skills_on_skill_id"
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
    t.integer "status", default: 0
    t.integer "teacher_validation", default: 0
    t.float "time_estimate"
    t.string "time_unit"
    t.bigint "milestone_id"
    t.index ["list_id"], name: "index_cards_on_list_id"
    t.index ["milestone_id"], name: "index_cards_on_milestone_id"
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

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id", "group_id"], name: "index_group_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "ue_id", null: false
    t.string "label", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ue_id", "label"], name: "index_groups_on_ue_id_and_label", unique: true
    t.index ["ue_id"], name: "index_groups_on_ue_id"
  end

  create_table "import_runs", force: :cascade do |t|
    t.string "source", null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.integer "created_count", default: 0
    t.integer "updated_count", default: 0
    t.integer "unchanged_count", default: 0
    t.integer "deleted_count", default: 0
    t.integer "kept_count", default: 0
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at"], name: "index_import_runs_on_started_at"
  end

  create_table "lesson_groups", force: :cascade do |t|
    t.bigint "lesson_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_lesson_groups_on_group_id"
    t.index ["lesson_id", "group_id"], name: "index_lesson_groups_on_lesson_id_and_group_id", unique: true
    t.index ["lesson_id"], name: "index_lesson_groups_on_lesson_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.bigint "ue_id"
    t.bigint "teacher_id"
    t.string "ade_uid"
    t.string "title", null: false
    t.string "room"
    t.string "teacher_label"
    t.integer "category", default: 0, null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "attendance_code"
    t.datetime "locked_at"
    t.datetime "validated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "manuelle", default: false, null: false
    t.index ["ade_uid"], name: "index_lessons_on_ade_uid"
    t.index ["batch_id", "starts_at"], name: "index_lessons_on_batch_id_and_starts_at"
    t.index ["batch_id"], name: "index_lessons_on_batch_id"
    t.index ["manuelle"], name: "index_lessons_on_manuelle"
    t.index ["starts_at"], name: "index_lessons_on_starts_at"
    t.index ["teacher_id"], name: "index_lessons_on_teacher_id"
    t.index ["ue_id"], name: "index_lessons_on_ue_id"
  end

  create_table "lists", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.integer "position"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_lists_on_team_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "referential_id", null: false
    t.string "place"
    t.datetime "date"
    t.integer "progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.index ["referential_id"], name: "index_meetings_on_referential_id"
    t.index ["team_id"], name: "index_meetings_on_team_id"
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

  create_table "milestones", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "name", null: false
    t.text "description"
    t.date "starts_on"
    t.date "due_on"
    t.integer "position"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "position"], name: "index_milestones_on_team_id_and_position"
    t.index ["team_id"], name: "index_milestones_on_team_id"
  end

  create_table "presences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "meeting_id", null: false
    t.integer "progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meeting_id"], name: "index_presences_on_meeting_id"
    t.index ["user_id"], name: "index_presences_on_user_id"
  end

  create_table "project_specialities", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "speciality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "speciality_id"], name: "index_project_specialities_on_project_id_and_speciality_id", unique: true
    t.index ["project_id"], name: "index_project_specialities_on_project_id"
    t.index ["speciality_id"], name: "index_project_specialities_on_speciality_id"
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
    t.bigint "batch_id"
    t.string "partner"
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

  create_table "referentials", force: :cascade do |t|
    t.string "title"
    t.boolean "active"
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id"], name: "index_referentials_on_batch_id"
  end

  create_table "skill_blocks", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.bigint "referential_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referential_id"], name: "index_skill_blocks_on_referential_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "title"
    t.integer "position"
    t.bigint "skill_block_id", null: false
    t.integer "evaluated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_block_id"], name: "index_skills_on_skill_block_id"
  end

  create_table "specialities", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position"
    t.bigint "parent_id"
    t.integer "project_access", default: 0, null: false
    t.boolean "exclusive_groups", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_id", "slug"], name: "index_specialities_on_batch_id_and_slug", unique: true
    t.index ["batch_id"], name: "index_specialities_on_batch_id"
    t.index ["parent_id"], name: "index_specialities_on_parent_id"
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
    t.bigint "user_id"
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

  create_table "tutoring_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ue_id"], name: "index_tutoring_requests_on_ue_id"
    t.index ["user_id", "ue_id"], name: "index_tutoring_requests_on_user_id_and_ue_id", unique: true
    t.index ["user_id"], name: "index_tutoring_requests_on_user_id"
  end

  create_table "ue_assessments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ue_id", null: false
    t.integer "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "home_hours", default: 0.0, null: false
    t.index ["ue_id"], name: "index_ue_assessments_on_ue_id"
    t.index ["user_id", "ue_id"], name: "index_ue_assessments_on_user_id_and_ue_id", unique: true
    t.index ["user_id"], name: "index_ue_assessments_on_user_id"
  end

  create_table "ue_guests", force: :cascade do |t|
    t.bigint "ue_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "student_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.boolean "permanent", default: true, null: false
    t.index ["ue_id", "permanent"], name: "index_ue_guests_on_ue_id_and_permanent"
    t.index ["ue_id"], name: "index_ue_guests_on_ue_id"
    t.index ["user_id"], name: "index_ue_guests_on_user_id"
  end

  create_table "ues", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.string "code"
    t.integer "position"
    t.index ["batch_id", "name"], name: "index_ues_on_batch_id_and_name", unique: true
    t.index ["batch_id", "position"], name: "index_ues_on_batch_id_and_position"
    t.index ["batch_id"], name: "index_ues_on_batch_id"
  end

  create_table "user_skill_statuses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "skill_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_user_skill_statuses_on_skill_id"
    t.index ["user_id", "skill_id"], name: "index_user_skill_statuses_on_user_id_and_skill_id", unique: true
    t.index ["user_id"], name: "index_user_skill_statuses_on_user_id"
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
    t.bigint "batch_id"
    t.boolean "drop", default: false
    t.bigint "speciality_id"
    t.boolean "imported", default: false, null: false
    t.string "td"
    t.string "tp"
    t.string "ade_label"
    t.index ["ade_label"], name: "index_users_on_ade_label"
    t.index ["batch_id"], name: "index_users_on_batch_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["speciality_id"], name: "index_users_on_speciality_id"
    t.index ["td"], name: "index_users_on_td"
    t.index ["team_id"], name: "index_users_on_team_id"
    t.index ["tp"], name: "index_users_on_tp"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "cards"
  add_foreign_key "assignments", "users"
  add_foreign_key "attempts", "exercices"
  add_foreign_key "attempts", "users"
  add_foreign_key "attendances", "lessons"
  add_foreign_key "attendances", "users"
  add_foreign_key "card_skills", "cards"
  add_foreign_key "card_skills", "skills"
  add_foreign_key "cards", "lists"
  add_foreign_key "cards", "milestones"
  add_foreign_key "exercices", "courses"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "ues"
  add_foreign_key "lesson_groups", "groups"
  add_foreign_key "lesson_groups", "lessons"
  add_foreign_key "lessons", "batches"
  add_foreign_key "lessons", "ues"
  add_foreign_key "lessons", "users", column: "teacher_id"
  add_foreign_key "lists", "teams"
  add_foreign_key "meetings", "referentials"
  add_foreign_key "meetings", "teams"
  add_foreign_key "messages", "teams"
  add_foreign_key "messages", "users"
  add_foreign_key "milestones", "teams"
  add_foreign_key "presences", "meetings"
  add_foreign_key "presences", "users"
  add_foreign_key "project_specialities", "projects"
  add_foreign_key "project_specialities", "specialities"
  add_foreign_key "projects", "batches"
  add_foreign_key "ratings", "projects"
  add_foreign_key "ratings", "users"
  add_foreign_key "referentials", "batches"
  add_foreign_key "skill_blocks", "referentials"
  add_foreign_key "skills", "skill_blocks"
  add_foreign_key "specialities", "batches"
  add_foreign_key "specialities", "specialities", column: "parent_id"
  add_foreign_key "supervisions", "projects"
  add_foreign_key "supervisions", "users"
  add_foreign_key "teams", "projects"
  add_foreign_key "teams", "users"
  add_foreign_key "tickets", "courses"
  add_foreign_key "tickets", "users"
  add_foreign_key "tutoring_requests", "ues"
  add_foreign_key "tutoring_requests", "users"
  add_foreign_key "ue_assessments", "ues"
  add_foreign_key "ue_assessments", "users"
  add_foreign_key "ue_guests", "ues"
  add_foreign_key "ue_guests", "users"
  add_foreign_key "ues", "batches"
  add_foreign_key "user_skill_statuses", "skills"
  add_foreign_key "user_skill_statuses", "users"
  add_foreign_key "users", "batches"
  add_foreign_key "users", "specialities"
  add_foreign_key "users", "teams"
end
