# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20151029131436) do

  create_table "combinations", force: :cascade do |t|
    t.integer  "dhcp_fingerprint_id",  limit: 4
    t.integer  "user_agent_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "device_id",            limit: 4
    t.string   "version",              limit: 255
    t.integer  "dhcp_vendor_id",       limit: 4
    t.integer  "score",                limit: 4,   default: 0
    t.integer  "mac_vendor_id",        limit: 4
    t.integer  "submitter_id",         limit: 4
    t.integer  "dhcp6_fingerprint_id", limit: 4
    t.integer  "dhcp6_enterprise_id",  limit: 4
    t.boolean  "fixed",                            default: false
  end

  add_index "combinations", ["dhcp6_enterprise_id"], name: "combinations_dhcp6_enterprise_id_ix", using: :btree
  add_index "combinations", ["dhcp6_fingerprint_id"], name: "combinations_dhcp6_fingerprint_id_ix", using: :btree
  add_index "combinations", ["dhcp_fingerprint_id"], name: "combinations_dhcp_fingerprint_id_ix", using: :btree
  add_index "combinations", ["dhcp_vendor_id"], name: "combinations_dhcp_vendor_id_ix", using: :btree
  add_index "combinations", ["mac_vendor_id"], name: "combinations_mac_vendor_id_ix", using: :btree
  add_index "combinations", ["user_agent_id"], name: "combinations_user_agent_id_ix", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.string   "value",      limit: 255
    t.integer  "rule_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",        limit: 255
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "devices", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.boolean  "mobile"
    t.boolean  "tablet"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",    limit: 4
    t.boolean  "inherit"
    t.integer  "submitter_id", limit: 4
    t.boolean  "approved",                 default: true
  end

  create_table "dhcp6_enterprises", force: :cascade do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dhcp6_enterprises", ["value"], name: "index_dhcp6_enterprises_on_value", length: {"value"=>255}, using: :btree

  create_table "dhcp6_fingerprints", force: :cascade do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dhcp6_fingerprints", ["value"], name: "index_dhcp6_fingerprints_on_value", length: {"value"=>255}, using: :btree

  create_table "dhcp_fingerprints", force: :cascade do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ignored",                 default: false
  end

  add_index "dhcp_fingerprints", ["value"], name: "index_dhcp_fingerprints_on_value", length: {"value"=>255}, using: :btree

  create_table "dhcp_vendors", force: :cascade do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dhcp_vendors", ["value"], name: "index_dhcp_vendors_on_value", length: {"value"=>255}, using: :btree

  create_table "discoverers", force: :cascade do |t|
    t.integer  "device_id",       limit: 4
    t.integer  "device_rule_id",  limit: 4
    t.integer  "version_rule_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description",     limit: 255
    t.integer  "priority",        limit: 4
    t.string   "version",         limit: 255
  end

  create_table "events", force: :cascade do |t|
    t.text     "value",      limit: 4294967295
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",      limit: 255
  end

  create_table "fingerprints_os", force: :cascade do |t|
    t.integer "device_id",      limit: 4
    t.integer "fingerprint_id", limit: 4
  end

  create_table "mac_vendors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "mac",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mac_vendors", ["mac"], name: "index_mac_vendors_on_mac", unique: true, using: :btree

  create_table "pending_combinations", force: :cascade do |t|
    t.integer  "owner_id",       limit: 4
    t.integer  "combination_id", limit: 4
    t.integer  "new_device_id",  limit: 4
    t.string   "new_version",    limit: 255
    t.text     "comment",        limit: 65535
    t.boolean  "completed",                    default: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  create_table "query_logs", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "combination_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rules", force: :cascade do |t|
    t.string   "value",                 limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "device_discoverer_id",  limit: 4
    t.integer  "version_discoverer_id", limit: 4
  end

  create_table "temp_combinations", force: :cascade do |t|
    t.string   "dhcp_fingerprint",  limit: 1000
    t.string   "user_agent",        limit: 1000
    t.string   "dhcp_vendor",       limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mac_vendor",        limit: 1000
    t.string   "dhcp6_fingerprint", limit: 1000
    t.string   "dhcp6_enterprise",  limit: 1000
    t.string   "oui",               limit: 6
  end

  create_table "test", force: :cascade do |t|
  end

  create_table "user_agents", force: :cascade do |t|
    t.string   "value",      limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_agents", ["value"], name: "index_user_agents_on_value", length: {"value"=>255}, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "github_uid",          limit: 255
    t.string   "name",                limit: 255,             null: false
    t.string   "display_name",        limit: 255
    t.integer  "level",               limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key",                 limit: 255
    t.integer  "requests",            limit: 4
    t.string   "email",               limit: 255
    t.boolean  "blocked"
    t.integer  "timeframed_requests", limit: 4,   default: 0
    t.integer  "search_count",        limit: 4,   default: 0
  end

  create_table "watched_combinations", force: :cascade do |t|
    t.integer  "combination_id", limit: 4
    t.integer  "user_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
