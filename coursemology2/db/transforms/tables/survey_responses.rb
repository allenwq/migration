def transform_survey_responses(course_ids = [])
  transform_table :survey_submissions,
                  to: ::Course::Survey::Response,
                  default_scope: proc { within_courses(course_ids).includes(:user_course) } do
    before_transform do |old|
      # Lots of surveys in v1 has an deleted course user
      old.user_course.present?
    end

    primary_key :id
    column :survey_id, to: :survey_id do |survey_id|
      V1::Source::Survey.transform(survey_id)
    end
    column :submitted_at, to: :submitted_at do |old|
      source_record.status == 'submitted' ? old : nil
    end
    column to: :creator_id do
      cu_id = V1::Source::UserCourse.transform(source_record.user_course_id)
      user = ::User.joins(:course_users).where('course_users.id = ?', cu_id).first
      user.id if user
    end
    column to: :updater_id do
      creator_id
    end

    column :created_at
    column :updated_at

    before_save do |old, new|
      exp = new.acting_as
      exp.creator_id = new.creator_id
      exp.updater_id = new.updater_id
      exp.created_at = old.created_at
      exp.updated_at = old.updated_at
      exp.course_user_id = V1::Source::UserCourse.transform(old.user_course_id)

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

      true
    end

    skip_saving_unless_valid
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