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

ActiveRecord::Schema[7.1].define(version: 2024_12_12_113624) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "schedules", force: :cascade do |t|
    t.bigint "spot_id", null: false
    t.integer "order_number", null: false
    t.integer "day_number", null: false
    t.integer "time_zone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spot_id"], name: "index_schedules_on_spot_id"
  end

  create_table "spots", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category", null: false
    t.decimal "lat", precision: 10, scale: 8
    t.decimal "lng", precision: 11, scale: 8
    t.bigint "travel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_number"
    t.integer "day_number"
    t.string "time_zone"
    t.index ["travel_id"], name: "index_spots_on_travel_id"
  end

  create_table "travel_members", force: :cascade do |t|
    t.bigint "travel_id", null: false
    t.bigint "user_id"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["travel_id", "user_id"], name: "index_travel_members_on_travel_id_and_user_id", unique: true
    t.index ["travel_id"], name: "index_travel_members_on_travel_id"
    t.index ["user_id"], name: "index_travel_members_on_user_id"
  end

  create_table "travels", force: :cascade do |t|
    t.string "title", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.string "thumbnail"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_travels_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "schedules", "spots"
  add_foreign_key "spots", "travels"
  add_foreign_key "travel_members", "travels"
  add_foreign_key "travel_members", "users"
  add_foreign_key "travels", "users"
end
