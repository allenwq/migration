def transform_assessment_mcq_options(course_ids = [])
  transform_table :assessment_mcq_options,
                  to: ::Course::Assessment::Question::MultipleResponseOption,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :question_id, to: :question_id do |question_id|
      V1::Source::AssessmentMcqQuestion.transform(question_id)
    end
    column to: :option do
      ContentParser.parse_mc_tags(source_record.text)
    end
    column :correct
    column :explanation
    column to: :weight do
      # There's no weight in v1, use ID instead
      source_record.id
    end

    skip_saving_unless_valid
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