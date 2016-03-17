def transform_assessment_programming_questions(course_ids = [])
  transform_table :assessment_coding_questions,
                  to: ::Course::Assessment::Question::Programming,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :assessment_id do
      original_assessment_id = source_record.assessment_question.assessments.first.id
      CoursemologyV1::Source::Assessment.transform(original_assessment_id)
    end
    column to: :description do
      source_record.assessment_question.description
    end
    column to: :maximum_grade do
      source_record.assessment_question.max_grade.to_i
    end
    column to: :weight do
      source_record.assessment_question.question_assessments.first.position
    end
    column to: :title do
      origin_title = source_record.assessment_question.title
      origin_title.present? ? origin_title : '( No Title )'
    end
    column to: :language_id do
      # V1: 1 => python3.3, 2 => python3.4, 3 => python2.7, 4 => python3.5
      # V2: 1 => python2.7, 2 => python3.4
      case source_record.language_id
      when 3
        1
      else
        2
      end
    end
    column to: :memory_limit do
      source_record.memory_limit || 0
    end
    column to: :time_limit do
      source_record.time_limit || 0
    end
    column to: :creator_id do
      CoursemologyV1::Source::User.transform(source_record.assessment_question.creator_id)
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_assessment_questions", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",  limit: 255, index: {name: "index_course_assessment_questions_actable", with: ["actable_id"], unique: true}
#   t.integer  "assessment_id", null: false, index: {name: "fk__course_assessment_questions_assessment_id"}, foreign_key: {references: "course_assessments", name: "fk_course_assessment_questions_assessment_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",         limit: 255,             null: false
#   t.text     "description"
#   t.integer  "maximum_grade", null: false
#   t.integer  "weight",        default: 0, null: false
#   t.integer  "creator_id",    null: false, index: {name: "fk__course_assessment_questions_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessment_questions_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",    null: false, index: {name: "fk__course_assessment_questions_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessment_questions_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",    null: false
#   t.datetime "updated_at",    null: false
# end
# create_table "course_assessment_question_programming", force: :cascade do |t|
#   t.integer "language_id",   null: false, index: {name: "fk__course_assessment_question_programming_language_id"}, foreign_key: {references: "polyglot_languages", name: "fk_course_assessment_question_programming_language_id", on_update: :no_action, on_delete: :no_action}
#   t.integer "memory_limit",  comment: "Memory limit, in MiB"
#   t.integer "time_limit",    comment: "Time limit, in seconds"
#   t.uuid    "import_job_id", comment: "The ID of the importing job", index: {name: "index_course_assessment_question_programming_on_import_job_id", unique: true}, foreign_key: {references: "jobs", name: "fk_course_assessment_question_programming_import_job_id", on_update: :no_action, on_delete: :nullify}
# end

# V1
# create_table "assessment_questions", :force => true do |t|
#   t.integer  "as_question_id"
#   t.string   "as_question_type"
#   t.integer  "creator_id"
#   t.integer  "dependent_id"
#   t.string   "title"
#   t.text     "description"
#   t.float    "max_grade"
#   t.integer  "attempt_limit"
#   t.boolean  "file_submission",  :default => false
#   t.text     "staff_comments"
#   t.datetime "deleted_at"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
# end
# create_table "assessment_coding_questions", :force => true do |t|
#   t.integer  "language_id"
#   t.boolean  "auto_graded"
#   t.text     "tests"
#   t.integer  "memory_limit"
#   t.integer  "time_limit"
#   t.text     "template"
#   t.text     "pre_include"
#   t.text     "append_code"
#   t.datetime "deleted_at"
#   t.datetime "created_at",   :null => false
#   t.datetime "updated_at",   :null => false
# end