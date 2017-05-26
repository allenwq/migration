class SurveyTextAnswerTable < BaseTable
  table_name 'survey_essay_answers'
  scope { |ids| within_courses(ids).includes(:user_course) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Survey::Answer.new
      
      migrate(old, new) do
        column :question_id do
          store.get(V1::SurveyQuestion.table_name, old.question_id)
        end
        column :response_id do
          store.get(V1::SurveySubmission.table_name, old.survey_submission_id)
        end
        column :text => :text_response
        column :creator_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end
        column :updater_id do
          new.creator_id
        end

        column :created_at
        column :updated_at

        skip_saving_unless_valid
        
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class SurveyMrqAnswerOptionTable < BaseTable
  table_name 'survey_mrq_answers'
  scope { |ids| within_courses(ids).includes(:user_course) }

  def migrate_batch(batch)
    #TODO: create mrq answers
    # batch.each do |old|
    #   new = ::Course::Survey::AnswerOption.new
    #
    #   migrate(old, new) do
    #     column :question_id do |old|
    #       store.get(V1::SurveyQuestion.table_name, old.question_id)
    #     end
    #     column :response_id do
    #       store.get(V1::SurveySubmission.table_name, old.survey_submission_id)
    #     end
    #     column :creator_id do
    #       store.get(V1::User.table_name, old.user_course.user_id)
    #     end
    #     column :updater_id do
    #       new.creator_id
    #     end
    #
    #     column :created_at
    #     column :updated_at
    #
    #     skip_saving_unless_valid
    #
    #     store.set(model.table_name, old.id, new.id)
    #   end
    # end
  end
end

# Schema
#
# V2:
# create_table "course_survey_answers", force: :cascade do |t|
#   t.integer  "question_id",   :null=>false, :index=>{:name=>"fk__course_survey_answers_question_id"}, :foreign_key=>{:references=>"course_survey_questions", :name=>"fk_course_survey_answers_question_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "response_id",   :null=>false, :index=>{:name=>"fk__course_survey_answers_response_id"}, :foreign_key=>{:references=>"course_survey_responses", :name=>"fk_course_survey_answers_response_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.text     "text_response"
#   t.integer  "creator_id",    :null=>false, :index=>{:name=>"fk__course_survey_answers_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_answers_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",    :null=>false, :index=>{:name=>"fk__course_survey_answers_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_answers_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",    :null=>false
#   t.datetime "updated_at",    :null=>false
# end
#
# create_table "course_survey_answer_options", force: :cascade do |t|
#   t.integer "answer_id",          :null=>false, :index=>{:name=>"fk__course_survey_answer_options_answer_id"}, :foreign_key=>{:references=>"course_survey_answers", :name=>"fk_course_survey_answer_options_answer_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer "question_option_id", :null=>false, :index=>{:name=>"fk__course_survey_answer_options_question_option_id"}, :foreign_key=>{:references=>"course_survey_question_options", :name=>"fk_course_survey_answer_options_question_option_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.boolean "selected",           :default=>false, :null=>false
# end

# V1
# create_table "survey_essay_answers", :force => true do |t|
#   t.integer  "user_course_id"
#   t.integer  "question_id"
#   t.text     "text"
#   t.time     "deleted_at"
#   t.datetime "created_at",           :null => false
#   t.datetime "updated_at",           :null => false
#   t.integer  "survey_submission_id"
# end
#
# create_table "survey_mrq_answers", :force => true do |t|
#   t.text     "selected_options", The field is not used
#   t.integer  "user_course_id"
#   t.integer  "question_id"
#   t.time     "deleted_at"
#   t.datetime "created_at",           :null => false
#   t.datetime "updated_at",           :null => false
#   t.integer  "option_id"
#   t.integer  "survey_submission_id"
# end
