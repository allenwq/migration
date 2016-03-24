def transform_assessment_mcq_answer_options(course_ids = [])
  transform_table :assessment_answer_options,
                  to: ::Course::Assessment::Answer::MultipleResponseOption,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :answer_id do
      CoursemologyV1::Source::AssessmentMcqAnswer.transform(source_record.answer_id)
    end
    column to: :option_id do
      CoursemologyV1::Source::AssessmentMcqOption.transform(source_record.option_id)
    end

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_assessment_answer_multiple_response_options", force: :cascade do |t|
#   t.integer "answer_id", null: false, index: {name: "fk__course_assessment_multiple_response_option_answer"}, foreign_key: {references: "course_assessment_answer_multiple_responses", name: "fk_course_assessment_answer_multiple_response_options_answer_id", on_update: :no_action, on_delete: :no_action}
#   t.integer "option_id", null: false, index: {name: "fk__course_assessment_multiple_response_option_question_option"}, foreign_key: {references: "course_assessment_question_multiple_response_options", name: "fk_course_assessment_answer_multiple_response_options_option_id", on_update: :no_action, on_delete: :no_action}
# end

# V1
# create_table "assessment_answer_options", :force => true do |t|
#   t.integer  "answer_id"
#   t.integer  "option_id"
#   t.datetime "deleted_at"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end