class CourseUserTable < BaseTable
  table_name 'user_courses'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::CourseUser.new

      migrate(old, new) do
        column :user_id do
          store.get(V1::User.table_name, old.user_id)
        end
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name
        column :is_phantom => :phantom
        column :role do
          case old.role_id
          when 3
            :owner
          when 4
            :teaching_assistant
          else
            :student
          end
        end
        column :last_active_time => :last_active_at
        column :updated_at
        column :created_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id) if new.persisted?
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_users", force: :cascade do |t|
#   t.integer  "course_id",      :null=>false, :index=>{:name=>"fk__course_users_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_users_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "user_id",        :null=>false, :index=>{:name=>"fk__course_users_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_users_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "role",           :default=>0, :null=>false
#   t.string   "name",           :limit=>255, :null=>false
#   t.boolean  "phantom",        :default=>false, :null=>false
#   t.datetime "last_active_at"
#   t.datetime "created_at",     :null=>false
#   t.datetime "updated_at",     :null=>false
#   t.integer  "creator_id",     :null=>false, :index=>{:name=>"fk__course_users_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_users_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",     :null=>false, :index=>{:name=>"fk__course_users_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_users_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
# end

# V1
# create_table "user_courses", :force => true do |t|
#   t.integer  "user_id"
#   t.integer  "course_id"
#   t.integer  "exp"
#   t.integer  "role_id"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
#   t.integer  "level_id"
#   t.time     "deleted_at"
#   t.boolean  "is_phantom",       :default => false
#   t.datetime "exp_updated_at"
#   t.string   "name"
#   t.datetime "last_active_time"
# end