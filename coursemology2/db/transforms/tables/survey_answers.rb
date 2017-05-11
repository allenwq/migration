def transform_survey_answers(course_ids = [])
  transform_table :survey_essay_answers,
                  to: ::Course::Survey::Answer,
                  default_scope: proc { within_courses(course_ids).includes(:user_course) } do
    primary_key :id
    column :question_id, to: :question_id do |old|
      V1::Source::SurveyQuestion.transform(old)
    end
    column :survey_submission_id, to: :response_id do |old|
      V1::Source::SurveySubmission.transform(old)
    end
    column :text, to: :text_response
    column to: :creator_id do
      V1::Source::User.transform(source_record.user_course.user_id)
    end
    column to: :updater_id do
      creator_id
    end

    column :created_at
    column :updated_at

    skip_saving_unless_valid
  end
  #
  # transform_table :survey_mrq_answers,
  #                 to: ::Course::Survey::AnswerOption,
  #                 default_scope: proc { within_courses(course_ids).includes(:user_course) } do
  #   primary_key :id
  #   column :question_id, to: :question_id do |old|
  #     V1::Source::SurveyQuestion.transform(old)
  #   end
  #   column :survey_submission_id, to: :response_id do |old|
  #     V1::Source::SurveySubmission.transform(old)
  #   end
  #   column to: :creator_id do
  #     V1::Source::User.transform(source_record.user_course.user_id)
  #   end
  #   column to: :updater_id do
  #     creator_id
  #   end
  #
  #   column :created_at
  #   column :updated_at
  #
  #   skip_saving_unless_valid
  # end
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
