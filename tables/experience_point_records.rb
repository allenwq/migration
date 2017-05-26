class ExpRecordTable < BaseTable
  table_name 'exp_transactions'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::ExperiencePointsRecord.new
      
      migrate(old, new) do
        column :exp => :points_awarded
        column :reason do
          old.reason || '( No Reason )'
        end
        column :course_user_id do
          store.get(V1::UserCourse.table_name, old.user_course_id)
        end
        column :creator_id do
          result = store.get(V1::Course.table_name, old.giver_id)
          new.updater_id = result
          result
        end
        column :updater_id do
          store.get(V1::Course.table_name, old.giver_id)
        end

        column :giver_id => :awarder_id
        column :awarded_at do
          old.created_at
        end

        column :created_at
        column :updated_at
        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
#
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

# V1:
#
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
