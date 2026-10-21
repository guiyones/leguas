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

ActiveRecord::Schema[8.1].define(version: 2026_10_21_201637) do
  create_table "auth_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "code"], name: "index_auth_tokens_on_user_id_and_code"
    t.index ["user_id"], name: "index_auth_tokens_on_user_id"
  end

  create_table "celebrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_celebrations_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_celebrations_on_user_id"
  end

  create_table "missions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "date", null: false
    t.decimal "goal_km", precision: 4, scale: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_missions_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_missions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.datetime "last_active_at"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stair_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "climbed_on", null: false
    t.integer "climbs", null: false
    t.decimal "load_kg", precision: 4, scale: 1
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "climbed_on"], name: "index_stair_sessions_on_user_id_and_climbed_on"
    t.index ["user_id"], name: "index_stair_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "name"
    t.decimal "daily_goal_km", precision: 4, scale: 1, default: "3.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stair_steps"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "walks", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "walked_on", null: false
    t.decimal "km", precision: 5, scale: 2, null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "load_kg", precision: 4, scale: 1
    t.index ["user_id", "walked_on"], name: "index_walks_on_user_id_and_walked_on"
    t.index ["user_id"], name: "index_walks_on_user_id"
  end

  add_foreign_key "auth_tokens", "users"
  add_foreign_key "celebrations", "users"
  add_foreign_key "missions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "stair_sessions", "users"
  add_foreign_key "walks", "users"
end
