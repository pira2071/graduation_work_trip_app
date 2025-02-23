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

ActiveRecord::Schema[7.1].define(version: 2025_02_23_011114) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "friendships", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "receiver_id", null: false
    t.string "status", default: "pending"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_friendships_on_receiver_id"
    t.index ["requester_id", "receiver_id"], name: "index_friendships_on_requester_id_and_receiver_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.string "action", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "read"], name: "index_notifications_on_recipient_id_and_read"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "packing_items", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "checked", default: false
    t.bigint "packing_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["packing_list_id"], name: "index_packing_items_on_packing_list_id"
  end

  create_table "packing_lists", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_packing_lists_on_user_id"
  end

  create_table "photos", force: :cascade do |t|
    t.string "image", null: false
    t.bigint "travel_id", null: false
    t.bigint "user_id", null: false
    t.integer "day_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["travel_id"], name: "index_photos_on_travel_id"
    t.index ["user_id"], name: "index_photos_on_user_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "spot_id", null: false
    t.integer "order_number", null: false
    t.integer "day_number", null: false
    t.string "time_zone", default: "morning", null: false
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

  create_table "travel_reviews", force: :cascade do |t|
    t.bigint "travel_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["travel_id"], name: "index_travel_reviews_on_travel_id"
    t.index ["user_id"], name: "index_travel_reviews_on_user_id"
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
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "friendships", "users", column: "receiver_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "packing_items", "packing_lists"
  add_foreign_key "packing_lists", "users"
  add_foreign_key "photos", "travels"
  add_foreign_key "photos", "users"
  add_foreign_key "schedules", "spots"
  add_foreign_key "spots", "travels"
  add_foreign_key "travel_members", "travels"
  add_foreign_key "travel_members", "users"
  add_foreign_key "travel_reviews", "travels"
  add_foreign_key "travel_reviews", "users"
  add_foreign_key "travels", "users"
end
