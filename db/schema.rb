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

ActiveRecord::Schema[8.0].define(version: 2025_08_10_031746) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "kills", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "killer_id"
    t.bigint "victim_id", null: false
    t.string "weapon", null: false
    t.datetime "occurred_at", null: false
    t.boolean "world_kill", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["killer_id"], name: "index_kills_on_killer_id"
    t.index ["match_id"], name: "index_kills_on_match_id"
    t.index ["victim_id"], name: "index_kills_on_victim_id"
  end

  create_table "match_players", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "player_id", null: false
    t.integer "kills_count", default: 0, null: false
    t.integer "deaths_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "awards", default: [], array: true
    t.index ["match_id", "player_id"], name: "index_match_players_on_match_id_and_player_id", unique: true
    t.index ["match_id"], name: "index_match_players_on_match_id"
    t.index ["player_id"], name: "index_match_players_on_player_id"
  end

  create_table "matches", force: :cascade do |t|
    t.string "match_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "exceeded_player_limit", default: false, null: false
    t.index ["exceeded_player_limit"], name: "index_matches_on_exceeded_player_limit"
    t.index ["match_id"], name: "index_matches_on_match_id", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
  end

  add_foreign_key "kills", "matches"
  add_foreign_key "kills", "players", column: "killer_id"
  add_foreign_key "kills", "players", column: "victim_id"
  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "players"
end
