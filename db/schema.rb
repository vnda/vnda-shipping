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

ActiveRecord::Schema.define(version: 20161122112406) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "block_rules", force: :cascade do |t|
    t.integer   "shipping_method_id", null: false
    t.int4range "range",              null: false
  end

  add_index "block_rules", ["shipping_method_id"], name: "index_block_rules_on_shipping_method_id", using: :btree

  create_table "delivery_types", force: :cascade do |t|
    t.string   "name"
    t.boolean  "enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
  end

  create_table "map_rules", force: :cascade do |t|
    t.integer  "shipping_method_id",                                                               null: false
    t.decimal  "price",                                                   precision: 10, scale: 2
    t.integer  "deadline",                                                                         null: false
    t.string   "name",                                                                             null: false
    t.geometry "region",             limit: {:srid=>0, :type=>"polygon"}
  end

  add_index "map_rules", ["shipping_method_id"], name: "index_map_rules_on_shipping_method_id", using: :btree

  create_table "map_rules_periods", force: :cascade do |t|
    t.integer  "period_id"
    t.integer  "map_rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "periods", force: :cascade do |t|
    t.string   "name"
    t.time     "limit_time"
    t.text     "days_off"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
    t.text     "exception_date"
    t.text     "closed_date"
    t.integer  "days_ago",       default: 0
  end

  create_table "periods_zip_rules", force: :cascade do |t|
    t.integer  "period_id"
    t.integer  "zip_rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "places", force: :cascade do |t|
    t.integer   "shipping_method_id",             null: false
    t.string    "name",                           null: false
    t.datetime  "created_at"
    t.datetime  "updated_at"
    t.int4range "range"
    t.integer   "deadline",           default: 0, null: false
  end

  add_index "places", ["shipping_method_id"], name: "index_places_on_shipping_method_id", using: :btree

  create_table "quote_histories", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "cart_id"
    t.text     "external_request"
    t.text     "external_response"
    t.text     "quotations"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shipping_errors", force: :cascade do |t|
    t.string   "message"
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shipping_errors", ["shop_id"], name: "index_shipping_errors_on_shop_id", using: :btree

  create_table "shipping_friendly_errors", force: :cascade do |t|
    t.string   "message"
    t.string   "rule"
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shipping_friendly_errors", ["shop_id"], name: "index_shipping_friendly_errors_on_shop_id", using: :btree

  create_table "shipping_methods", force: :cascade do |t|
    t.integer  "shop_id",                                                                                   null: false
    t.string   "name",                                                                                      null: false
    t.string   "description",      default: "",                                                             null: false
    t.string   "slug",                                                                                      null: false
    t.boolean  "express",          default: false,                                                          null: false
    t.boolean  "enabled",          default: false,                                                          null: false
    t.numrange "weigth_range",     default: BigDecimal(-::Float::INFINITY)...BigDecimal(::Float::INFINITY), null: false
    t.integer  "delivery_type_id"
    t.string   "data_origin",      default: "local",                                                        null: false
    t.string   "service"
    t.string   "mid"
    t.text     "notice"
    t.integer  "norder"
  end

  add_index "shipping_methods", ["shop_id"], name: "index_shipping_methods_on_shop_id", using: :btree

  create_table "shops", force: :cascade do |t|
    t.string  "name",                                                 null: false
    t.string  "token",                    limit: 255,                 null: false
    t.string  "axado_token",              limit: 32
    t.boolean "forward_to_axado",                     default: false, null: false
    t.string  "correios_code"
    t.string  "correios_password"
    t.boolean "forward_to_correios",                  default: false, null: false
    t.string  "normal_shipping_name"
    t.string  "express_shipping_name"
    t.integer "backup_method_id"
    t.string  "intelipost_token"
    t.boolean "forward_to_intelipost",                default: false, null: false
    t.text    "correios_custom_services"
    t.string  "order_prefix",                         default: ""
    t.boolean "declare_value",                        default: true
    t.boolean "order_by_price",                       default: true
  end

  add_index "shops", ["name"], name: "index_shops_on_name", unique: true, using: :btree
  add_index "shops", ["token"], name: "index_shops_on_token", unique: true, using: :btree

  create_table "track_ceps", force: :cascade do |t|
    t.string  "service_name"
    t.integer "service_code",              null: false
    t.string  "state",                     null: false
    t.string  "type_city",                 null: false
    t.string  "name",                      null: false
    t.text    "tracks",       default: [],              array: true
  end

  add_index "track_ceps", ["service_code"], name: "index_track_ceps_on_service_code", using: :btree
  add_index "track_ceps", ["service_name"], name: "index_track_ceps_on_service_name", using: :btree

  create_table "track_weights", force: :cascade do |t|
    t.string  "service_name"
    t.integer "service_code",              null: false
    t.text    "tracks",       default: [],              array: true
  end

  add_index "track_weights", ["service_code"], name: "index_track_weights_on_service_code", using: :btree
  add_index "track_weights", ["service_name"], name: "index_track_weights_on_service_name", using: :btree

  create_table "zip_code_locations", force: :cascade do |t|
    t.string   "zip_code",                null: false
    t.hstore   "location",   default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zip_rules", force: :cascade do |t|
    t.integer   "shipping_method_id",                          null: false
    t.int4range "range",                                       null: false
    t.decimal   "price",              precision: 10, scale: 2
    t.integer   "deadline",                                    null: false
  end

  add_index "zip_rules", ["shipping_method_id"], name: "index_zip_rules_on_shipping_method_id", using: :btree

  create_table "zipcode_spreadsheets", force: :cascade do |t|
    t.integer "shop_id",                                                               null: false
    t.integer "delivery_type_id",                                                      null: false
    t.string  "service_name"
    t.integer "service_code"
    t.string  "zipcode_start",           limit: 8
    t.string  "zipcode_end",             limit: 8
    t.float   "weight_start"
    t.float   "weight_end"
    t.decimal "absolute_money_cost",               precision: 8, scale: 2
    t.decimal "price_percent",                     precision: 8, scale: 2
    t.decimal "price_by_extra_weight",             precision: 8, scale: 2
    t.integer "max_volume",                                                default: 0
    t.integer "time_cost"
    t.string  "country",                 limit: 3
    t.decimal "minimum_value_insurance",           precision: 8, scale: 2
  end

  add_index "zipcode_spreadsheets", ["delivery_type_id"], name: "index_zipcode_spreadsheets_on_delivery_type_id", using: :btree
  add_index "zipcode_spreadsheets", ["service_code"], name: "index_zipcode_spreadsheets_on_service_code", using: :btree
  add_index "zipcode_spreadsheets", ["service_name"], name: "index_zipcode_spreadsheets_on_service_name", using: :btree
  add_index "zipcode_spreadsheets", ["shop_id"], name: "index_zipcode_spreadsheets_on_shop_id", using: :btree
  add_index "zipcode_spreadsheets", ["zipcode_end"], name: "index_zipcode_spreadsheets_on_zipcode_end", using: :btree
  add_index "zipcode_spreadsheets", ["zipcode_start"], name: "index_zipcode_spreadsheets_on_zipcode_start", using: :btree

  add_foreign_key "block_rules", "shipping_methods"
  add_foreign_key "map_rules", "shipping_methods"
  add_foreign_key "places", "shipping_methods"
  add_foreign_key "shipping_methods", "shops"
  add_foreign_key "zip_rules", "shipping_methods"
end
