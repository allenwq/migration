class AssessmentMcqAnswerOptionTable < BaseTable
  table_name 'assessment_answer_options'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Answer::MultipleResponseOption.new
      
      migrate(old, new) do
        column :answer_id do
          store.get(V1::AssessmentMcqAnswer.table_name, old.answer_id)
        end
        column to: :option_id do
          store.get(V1::AssessmentMcqOption.table_name, old.option_id)
        end

        new.save validate: false

        store.set(model.name, old.id, new.id) if new.persisted?
      end
    end
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