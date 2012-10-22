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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121018150110) do

  create_table "puppet_modules", :force => true do |t|
    t.string   "name"
    t.string   "version"
    t.string   "source"
    t.string   "author"
    t.string   "license"
    t.string   "summary"
    t.string   "project_page"
    t.text     "description"
    t.text     "dependencies"
    t.text     "types"
    t.text     "checksums"
    t.boolean  "mirrored_from_remote", :default => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
  end

  add_index "puppet_modules", ["name", "version"], :name => "idx_name_version", :unique => true

end
