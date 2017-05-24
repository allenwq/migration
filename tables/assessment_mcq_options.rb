class AssessmentMcqOptionTable < BaseTable
  table_name 'assessment_mcq_options'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Question::MultipleResponseOption.new
      migrate(old, new) do
        column :question_id do
          store.get(V1::AssessmentMcqQuestion.table_name, old.question_id)
        end
        column :option do
          ContentParser.parse_mc_tags(old.text)
        end
        column :correct
        column :explanation
        column :weight do
          # There's no weight in v1, use ID instead
          old.id
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id) if new.id
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_assessment_question_multiple_response_options", force: :cascade do |t|
#   t.integer "question_id", :null=>false, :index=>{:name=>"fk__course_assessment_multiple_response_option_question"}, :foreign_key=>{:references=>"course_assessment_question_multiple_responses", :name=>"fk_course_assessment_question_multiple_response_options_questio", :on_update=>:no_action, :on_delete=>:no_action}
#   t.boolean "correct",     :null=>false
#   t.text    "option",      :null=>false
#   t.text    "explanation"
#   t.integer "weight",      :null=>false
# end

# V1
# create_table "assessment_mcq_options", :force => true do |t|
#   t.integer  "creator_id"
#   t.integer  "question_id"
#   t.text     "text"
#   t.text     "explanation"
#   t.boolean  "correct"
#   t.datetime "deleted_at"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
# end