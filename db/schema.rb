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

ActiveRecord::Schema.define(version: 20170426212131) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "postgis"

  create_table "block_rules", force: :cascade do |t|
    t.integer   "shipping_method_id", null: false
    t.int4range "range",              null: false
  end

  add_index "block_rules", ["shipping_method_id"], name: "index_block_rules_on_shipping_method_id", using: :btree

  create_table "delivery_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.boolean  "enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
  end

  create_table "map_rules", force: :cascade do |t|
    t.integer  "shipping_method_id",                                                               null: false
    t.decimal  "price",                                                   precision: 10, scale: 2
    t.integer  "deadline",                                                                         default: 0, null: false
    t.string   "name",               limit: 255,                                                   null: false
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
    t.string   "name",           limit: 255
    t.time     "limit_time"
    t.text     "days_off"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
    t.text     "exception_date"
    t.text     "closed_date"
    t.integer  "days_ago",                   default: 0
  end

  create_table "periods_zip_rules", force: :cascade do |t|
    t.integer  "period_id"
    t.integer  "zip_rule_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "picking_times", force: :cascade do |t|
    t.boolean "enabled", default: true,    null: false
    t.string  "weekday",                   null: false
    t.string  "hour",    default: "18:00", null: false
    t.integer "shop_id"
  end

  add_index "picking_times", ["enabled", "weekday"], name: "index_picking_times_on_enabled_and_weekday", using: :btree

  create_table "places", force: :cascade do |t|
    t.integer   "shipping_method_id",                         null: false
    t.string    "name",               limit: 255,             null: false
    t.datetime  "created_at"
    t.datetime  "updated_at"
    t.int4range "range"
    t.integer   "deadline",                       default: 0, null: false
  end

  add_index "places", ["shipping_method_id"], name: "index_places_on_shipping_method_id", using: :btree

  create_table "quotations", force: :cascade do |t|
    t.integer  "shop_id",                                                   null: false
    t.integer  "cart_id",                                                   null: false
    t.string   "package",                                                   null: false
    t.string   "name",                                                      null: false
    t.decimal  "price",              precision: 10, scale: 2, default: 0.0, null: false
    t.integer  "deadline",                                    default: 0,   null: false
    t.string   "slug",                                                      null: false
    t.string   "delivery_type"
    t.string   "delivery_type_slug"
    t.string   "deliver_company"
    t.text     "notice"
    t.string   "quotation_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.string   "skus",                                        default: [],  null: false, array: true
    t.integer  "shipping_method_id"
  end

  add_index "quotations", ["cart_id"], name: "index_quotations_on_cart_id", using: :btree
  add_index "quotations", ["shipping_method_id"], name: "index_quotations_on_shipping_method_id", using: :btree
  add_index "quotations", ["shop_id"], name: "index_quotations_on_shop_id", using: :btree

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
    t.string   "message",    limit: 255
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shipping_errors", ["shop_id"], name: "index_shipping_errors_on_shop_id", using: :btree

  create_table "shipping_friendly_errors", force: :cascade do |t|
    t.string   "message",    limit: 255
    t.string   "rule",       limit: 255
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shipping_friendly_errors", ["shop_id"], name: "index_shipping_friendly_errors_on_shop_id", using: :btree

  create_table "shipping_methods", force: :cascade do |t|
    t.integer  "shop_id",                                                                                               null: false
    t.string   "name",             limit: 255,                                                                          null: false
    t.string   "description",      limit: 255, default: "",                                                             null: false
    t.string   "slug",             limit: 255,                                                                          null: false
    t.boolean  "express",                      default: false,                                                          null: false
    t.boolean  "enabled",                      default: false,                                                          null: false
    t.numrange "weigth_range",                 default: BigDecimal("0.0")..BigDecimal("1000.0"),                        null: false
    t.integer  "delivery_type_id"
    t.string   "data_origin",      limit: 255, default: "local",                                                        null: false
    t.string   "service",          limit: 255
    t.string   "mid",              limit: 255
    t.text     "notice"
    t.integer  "norder"
    t.integer  "days_off",                     default: [],      null: false, array: true
  end

  add_index "shipping_methods", ["shop_id"], name: "index_shipping_methods_on_shop_id", using: :btree

  create_table "shops", force: :cascade do |t|
    t.string  "name",                     limit: 255,                 null: false
    t.string  "token",                    limit: 255,                 null: false
    t.string  "axado_token",              limit: 32
    t.boolean "forward_to_axado",                    default: false, null: false
    t.string  "correios_code",            limit: 255
    t.string  "correios_password",        limit: 255
    t.boolean "forward_to_correios",                 default: false, null: false
    t.string  "normal_shipping_name",     limit: 255
    t.string  "express_shipping_name",    limit: 255
    t.integer "backup_method_id"
    t.string  "intelipost_token",         limit: 255
    t.boolean "forward_to_intelipost",               default: false, null: false
    t.text    "correios_custom_services"
    t.string  "order_prefix",             limit: 255, default: ""
    t.boolean "declare_value",                        default: true
    t.boolean "order_by_price",                       default: true
    t.integer "marketplace_id",                       default: 0,     null: false
    t.string  "marketplace_tag"
    t.string  "zip"
    t.boolean "forward_to_tnt",                       default: false, null: false
    t.string  "tnt_email"
    t.string  "tnt_delivery_type"
    t.string  "tnt_cnpj"
    t.string  "tnt_ie"
    t.integer "tnt_service_id"
  end

  add_index "shops", ["marketplace_id"], name: "index_shops_on_marketplace_id", using: :btree
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
    t.string   "zip_code",   limit: 255,              null: false
    t.hstore   "location",               default: {}, null: false
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

  add_foreign_key "block_rules", "shipping_methods", name: "block_rules_shipping_method_id_fk"
  add_foreign_key "map_rules", "shipping_methods", name: "map_rules_shipping_method_id_fk"
  add_foreign_key "places", "shipping_methods", name: "places_shipping_method_id_fk"
  add_foreign_key "shipping_methods", "shops", name: "shipping_methods_shop_id_fk"
  add_foreign_key "zip_rules", "shipping_methods", name: "zip_rules_shipping_method_id_fk"
end
