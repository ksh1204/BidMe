# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101202065349) do

  create_table "bids", :force => true do |t|
    t.integer  "bidder_id"
    t.integer  "item_id"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ebay_items", :force => true do |t|
    t.integer  "ebay_id"
    t.string   "title"
    t.string   "country"
    t.string   "view_url"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "keyword"
  end

  create_table "follows", :force => true do |t|
    t.integer  "follower_id"
    t.integer  "following_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "items", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "item_category_id"
    t.float    "start_price"
    t.boolean  "bin",                     :default => false
    t.float    "bin_price"
    t.integer  "time_limit",              :default => 300
    t.string   "item_photo_file_name"
    t.string   "item_photo_content_type"
    t.integer  "item_photo_file_size"
    t.datetime "item_photo_updated_at"
    t.boolean  "delta",                   :default => true,  :null => false
    t.float    "current_price"
    t.boolean  "closed",                  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",                  :default => false
    t.integer  "time_limit_hours",        :default => 0
    t.integer  "time_limit_minutes",      :default => 0
  end

  create_table "messages", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "unread",      :default => true
  end

  create_table "rates", :force => true do |t|
    t.integer  "rater_id"
    t.integer  "rateable_id"
    t.string   "rateable_type"
    t.integer  "stars",         :null => false
    t.string   "dimension"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rates", ["rateable_id", "rateable_type"], :name => "index_rates_on_rateable_id_and_rateable_type"
  add_index "rates", ["rater_id"], :name => "index_rates_on_rater_id"

  create_table "transactions", :force => true do |t|
    t.integer  "buyer_id"
    t.integer  "seller_id"
    t.integer  "item_id"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "commentee_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_items", :force => true do |t|
    t.integer  "user_id"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                      :limit => 40
    t.string   "email",                      :limit => 100
    t.string   "crypted_password",           :limit => 40
    t.string   "salt",                       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",             :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",            :limit => 40
    t.datetime "activated_at"
    t.string   "last_ip"
    t.boolean  "is_admin",                                  :default => false
    t.boolean  "is_banned",                                 :default => false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "address"
    t.string   "phone"
    t.float    "money",                                     :default => 100.0
    t.string   "reset_code"
    t.boolean  "logged_in"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.integer  "money_refill",                              :default => 5
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "watches", :force => true do |t|
    t.integer  "watcher_id"
    t.integer  "item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
