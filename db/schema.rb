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

ActiveRecord::Schema.define(version: 20160802140634) do

  create_table "answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text     "text",          limit: 65535
    t.integer  "respondent_id"
    t.integer  "question_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["question_id"], name: "index_answers_on_question_id", using: :btree
    t.index ["respondent_id"], name: "index_answers_on_respondent_id", using: :btree
  end

  create_table "channels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "quiz_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "user"
    t.string   "password"
    t.string   "url"
    t.integer  "method"
    t.text     "settings",   limit: 65535
    t.index ["quiz_id"], name: "index_channels_on_quiz_id", using: :btree
  end

  create_table "questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "text",       limit: 65535
    t.integer  "quiz_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "kind",                     default: 0
    t.index ["quiz_id"], name: "index_questions_on_quiz_id", using: :btree
  end

  create_table "quizzes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "respondents", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "phone_number"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "survey_id"
    t.integer  "status"
    t.integer  "current_question_id"
    t.index ["current_question_id"], name: "index_respondents_on_current_question_id", using: :btree
    t.index ["survey_id"], name: "index_respondents_on_survey_id", using: :btree
  end

  create_table "surveys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.integer  "quiz_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "status"
    t.index ["quiz_id"], name: "index_surveys_on_quiz_id", using: :btree
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "answers", "respondents"
  add_foreign_key "channels", "quizzes"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "respondents", "surveys"
  add_foreign_key "surveys", "quizzes"
end
