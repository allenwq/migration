def transform_assessment_programming_answers(course_ids = [])
  transform_table :assessment_coding_answers,
                  to: ::Course::Assessment::Answer::Programming,
                  default_scope: proc { within_courses(course_ids).with_eager_load } do
    primary_key :id
    column to: :submission_id do
      V1::Source::AssessmentSubmission.transform(source_record.submission_id)
    end
    column :transform_question_id, to: :question_id
    column :transform_workflow_state, to: :workflow_state
    column :transform_submitted_at, to: :submitted_at
    column :transform_grade, to: :grade
    column :correct
    column to: :grader_id do
      if graded?
        id = nil
        if source_record.assessment_answer_grading
          id = V1::Source::User.transform(source_record.assessment_answer_grading.grader_id)
        end
        id || User::SYSTEM_USER_ID
      end
    end
    column :transform_graded_at, to: :graded_at
    column to: :updated_at do
      source_record.assessment_answer.updated_at
    end
    column :transform_created_at, to: :created_at

    column :content do |content|
      # There are strings ends with "\u0000" which result in a postgres error.
      self.files.build(filename: 'template.py', content: content.sub("\u0000", '')) if content.present?
    end

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_assessment_answers", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",   :limit=>255, :index=>{:name=>"index_course_assessment_answers_actable", :with=>["actable_id"], :unique=>true}
#   t.integer  "submission_id",  :null=>false, :index=>{:name=>"fk__course_assessment_answers_submission_id"}, :foreign_key=>{:references=>"course_assessment_submissions", :name=>"fk_course_assessment_answers_submission_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "question_id",    :null=>false, :index=>{:name=>"fk__course_assessment_answers_question_id"}, :foreign_key=>{:references=>"course_assessment_questions", :name=>"fk_course_assessment_answers_question_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "workflow_state", :limit=>255, :null=>false
#   t.datetime "submitted_at"
#   t.decimal  "grade",          :precision=>4, :scale=>1
#   t.boolean  "correct",        :comment=>"Correctness is independent of the grade (depends on the grading schema)"
#   t.integer  "grader_id",      :index=>{:name=>"fk__course_assessment_answers_grader_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_answers_grader_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "graded_at"
#   t.datetime "created_at",     :null=>false
#   t.datetime "updated_at",     :null=>false
# end
# create_table "course_assessment_answer_programming", force: :cascade do |t|
# end
# create_table "course_assessment_answer_programming_files", force: :cascade do |t|
#   t.integer "answer_id", null: false, index: {name: "fk__course_assessment_answer_programming_files_answer_id"}, foreign_key: {references: "course_assessment_answer_programming", name: "fk_course_assessment_answer_programming_files_answer_id", on_update: :no_action, on_delete: :no_action}
#   t.string  "filename",  limit: 255,              null: false
#   t.text    "content",   default: "", null: false
# end
# V1
# create_table "assessment_answers", :force => true do |t|
#   t.integer  "as_answer_id"
#   t.string   "as_answer_type"
#   t.integer  "submission_id"
#   t.integer  "question_id"
#   t.integer  "std_course_id"
#   t.text     "content",        :limit => 16777215
#   t.integer  "attempt_left",                       :default => 0
#   t.boolean  "finalised",                          :default => false
#   t.boolean  "correct",                            :default => false
#   t.datetime "deleted_at"
#   t.datetime "created_at",                                            :null => false
#   t.datetime "updated_at",                                            :null => false
# end
# create_table "assessment_coding_answers", :force => true do |t|
#   t.text     "result"
#   t.datetime "deleted_at"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end
# create_table "assessment_answer_gradings", :force => true do |t|
#   t.integer  "answer_id"
#   t.integer  "grading_id"
#   t.integer  "grader_id"
#   t.integer  "grader_course_id"
#   t.float    "grade"
#   t.datetime "deleted_at"
#   t.datetime "created_at",       :null => false
#   t.datetime "updated_at",       :null => false
# end