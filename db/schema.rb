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

ActiveRecord::Schema.define(version: 20140822180155) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "shipping_methods", force: true do |t|
    t.integer "shop_id",                     null: false
    t.string  "name",                        null: false
    t.string  "description", default: "",    null: false
    t.string  "slug",                        null: false
    t.boolean "express",     default: false, null: false
  end

  add_index "shipping_methods", ["shop_id"], name: "index_shipping_methods_on_shop_id", using: :btree
  add_index "shipping_methods", ["slug"], name: "index_shipping_methods_on_slug", unique: true, using: :btree

  create_table "shops", force: true do |t|
    t.string "name",                   null: false
    t.string "token",       limit: 32, null: false
    t.string "axado_token", limit: 32
  end

  add_index "shops", ["name"], name: "index_shops_on_name", unique: true, using: :btree
  add_index "shops", ["token"], name: "index_shops_on_token", unique: true, using: :btree

  create_table "zip_rules", force: true do |t|
    t.integer   "shipping_method_id",                          null: false
    t.int4range "range",                                       null: false
    t.decimal   "price",              precision: 10, scale: 2
    t.integer   "deadline",                                    null: false
  end

  add_index "zip_rules", ["shipping_method_id"], name: "index_zip_rules_on_shipping_method_id", using: :btree

  add_foreign_key "shipping_methods", "shops", name: "shipping_methods_shop_id_fk"

  add_foreign_key "zip_rules", "shipping_methods", name: "zip_rules_shipping_method_id_fk"

end
