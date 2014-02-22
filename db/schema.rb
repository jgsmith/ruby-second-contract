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

ActiveRecord::Schema.define(version: 20140219132000) do

  create_table "characters", force: true do |t|
    t.string  "name"
    t.integer "item_id"
    t.integer "user_id"
  end

  create_table "domains", force: true do |t|
    t.string "name"
  end

  create_table "item_relationships", force: true do |t|
    t.integer "source_id"
    t.integer "target_id"
    t.integer "preposition", default: 0
    t.string  "detail",      default: "default"
    t.integer "x"
    t.integer "y"
    t.boolean "hidden",      default: false,     null: false
  end

  create_table "items", force: true do |t|
    t.string  "archetype_name",                                 null: false
    t.string  "traits",                    default: "--- {}\n"
    t.string  "skills",                    default: "--- {}\n"
    t.string  "stats",                     default: "--- {}\n"
    t.string  "details",                   default: "--- {}\n"
    t.string  "physicals",                 default: "--- {}\n"
    t.string  "counters",                  default: "--- {}\n"
    t.string  "resources",                 default: "--- {}\n"
    t.string  "flags",                     default: "--- {}\n"
    t.integer "domain_id"
    t.string  "name",           limit: 64
    t.boolean "transient",                 default: false,      null: false
  end

  create_table "users", force: true do |t|
    t.string "name"
    t.string "email"
    t.string "password"
    t.text   "settings", default: "--- {}\n", null: false
  end

end
