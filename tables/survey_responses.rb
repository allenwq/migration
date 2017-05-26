class SurveyResponseTable < BaseTable
  table_name 'survey_submissions'
  scope { |ids| within_courses(ids).includes(:user_course) }

  def migrate_batch(batch)
    batch.each do |old|
      # Lots of surveys in v1 has an deleted course user
      next if !old.user_course.present?
      
      new = ::Course::Survey::Response.new
      
      migrate(old, new) do
        column :survey_id do
          store.get(V1::Survey.table_name, old.survey_id)
        end
        column :submitted_at do
          old.status == 'submitted' ? old.submitted_at : nil
        end
        column :creator_id do
          cu_id = store.get(V1::UserCourse.table_name, old.user_course_id)
          user = ::User.joins(:course_users).where('course_users.id = ?', cu_id).first
          user.id if user
        end
        column :updater_id do
          new.creator_id
        end

        column :created_at
        column :updated_at

        # Migrate exp record
        exp = new.acting_as
        exp.creator_id = new.creator_id
        exp.updater_id = new.updater_id
        exp.created_at = old.created_at
        exp.updated_at = old.updated_at
        exp.course_user_id = store.get(V1::UserCourse.table_name, old.user_course_id)

        if old.status == 'submitted'
          exp.awarder_id = new.creator_id

          if old.exp_transaction
            exp.points_awarded = old.exp_transaction.exp
            exp.awarded_at = old.exp_transaction.created_at
          else
            exp.points_awarded = 0
            exp.awarded_at = new.created_at
          end
        end

        # Migrate MRQ answers, V1 MRQ answers are equal to answer_options in v2, must migrate here to make sure it's thread safe
        # TODO: wait for survey to change the schema
        # old.mrq_answers.group_by(&:question_id).each do |pair|
        #   question_id = store.get(V1::SurveyQuestion.table_name, pair[0])
        #   old_answers = pair[1]
        #   selected_option_ids = old_answers.map do |a|
        #     V1::SurveyQuestionOption.transform(a.option_id)
        #   end
        #   new_question = ::Course::Survey::Question.find(question_id)
        #   answer = new.answers.build(question_id: question_id)
        #   new_question.option_ids.each do |id|
        #     answer.options.build(question_option_id: id, selected: selected_option_ids.include?(id))
        #   end
        # end

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_experience_points_records", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",         :limit=>255, :index=>{:name=>"index_course_experience_points_records_on_actable", :with=>["actable_id"], :unique=>true}
#   t.integer  "draft_points_awarded"
#   t.integer  "points_awarded"
#   t.integer  "course_user_id",       :null=>false, :index=>{:name=>"fk__course_experience_points_records_course_user_id"}, :foreign_key=>{:references=>"course_users", :name=>"fk_course_experience_points_records_course_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "reason",               :limit=>255
#   t.integer  "creator_id",           :null=>false, :index=>{:name=>"fk__course_experience_points_records_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",           :null=>false, :index=>{:name=>"fk__course_experience_points_records_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",           :null=>false
#   t.datetime "updated_at",           :null=>false
#   t.integer  "awarder_id",           :index=>{:name=>"fk__course_experience_points_records_awarder_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_awarder_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "awarded_at"
# end

# create_table "course_survey_responses", force: :cascade do |t|
#   t.integer  "survey_id",    :null=>false, :index=>{:name=>"fk__course_survey_responses_survey_id"}, :foreign_key=>{:references=>"course_surveys", :name=>"fk_course_survey_responses_survey_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "submitted_at"
#   t.integer  "creator_id",   :null=>false, :index=>{:name=>"fk__course_survey_responses_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_responses_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",   :null=>false, :index=>{:name=>"fk__course_survey_responses_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_responses_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",   :null=>false
#   t.datetime "updated_at",   :null=>false
# end
# add_index "course_survey_responses", ["survey_id", "creator_id"], :name=>"index_course_survey_responses_on_survey_id_and_creator_id", :unique=>true

# V1
# create_table "survey_submissions", :force => true do |t|
#   t.integer  "user_course_id"
#   t.integer  "survey_id"
#   t.datetime "open_at",  This field is not used
#   t.datetime "submitted_at", all v1 fields has submitted_at set when status is submitted
#   t.string   "status",  ['started', 'submitted']
#   t.time     "deleted_at"
#   t.datetime "created_at",     :null => false
#   t.datetime "updated_at",     :null => false
#   t.integer  "current_qn", this step is for runes contest, can be calculated, will drop
# end

# create_table "exp_transactions", :force => true do |t|
#   t.integer  "exp"
#   t.string   "reason"
#   t.boolean  "is_valid"
#   t.integer  "user_course_id"
#   t.integer  "giver_id"
#   t.datetime "created_at",      :null => false
#   t.datetime "updated_at",      :null => false
#   t.time     "deleted_at"
#   t.integer  "rewardable_id"
#   t.string   "rewardable_type"
# end