class AssessmentScribingAnswerTable < BaseTable
  table_name 'assessment_scribing_answers'
  scope { |ids| within_courses(ids).with_eager_load }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Answer::Scribing.new

      migrate(old, new) do
        column :submission_id do
          store.get(V1::AssessmentSubmission.table_name, old.submission_id)
        end
        column :question_id do
          old.transform_question_id(store)
        end
        column :transform_workflow_state => :workflow_state
        column :transform_submitted_at => :submitted_at
        column :transform_grade => :grade
        column :correct
        column :grader_id do
          if new.graded?
            id = nil
            if old.assessment_answer_grading
              id = store.get(V1::User.table_name, old.assessment_answer_grading.grader_id)
            end
            id || User::SYSTEM_USER_ID
          end
        end
        column :transform_graded_at => :graded_at
        column :updated_at do
          old.assessment_answer.updated_at
        end
        column :transform_created_at => :created_at

        skip_saving_unless_valid

        store.set(V1::AssessmentAnswer.table_name, old.assessment_answer.id, new.acting_as.id)
        store.set(model.table_name, old.id, new.id)
      end
    end
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
# create_table "course_assessment_answer_scribings", force: :cascade do |t|
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
# create_table "assessment_scribing_answers", :force => true do |t|
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