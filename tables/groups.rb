class GroupTable < BaseTable
  table_name 'tutorial_groups'
  scope { |ids| within_courses(ids).order(:created_at).group_by(&:tut_course_id) }

  def migrate_batch(batch)
    hash = batch
    tutor_courses = V1::UserCourse.where(id: hash.keys)
    tutor_courses.each do |old|
      new = ::Course::Group.new

      migrate(old, new) do
        # Old here is a user course
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name do
          old.name
        end
        column :updated_at do
          hash[old.id].first.updated_at
        end
        column :created_at do
          hash[old.id].first.created_at
        end

        new_tutor_user_id = store.get(V1::UserCourse.table_name, old.id)
        new.group_users.build(course_user: ::CourseUser.find(new_tutor_user_id), role: :manager,
                              created_at: new.created_at, updated_at: new.updated_at,
                              creator: User.system, updater: User.system)
        skip_saving_unless_valid
      end
    end
  end
end

class GroupUserTable < BaseTable
  table_name 'tutorial_groups'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::GroupUser.new

      migrate(old, new) do
        column :group_id do
          new_tutor_id = store.get(V1::UserCourse.table_name, old.tut_course_id)
          ::Course::GroupUser.where(course_user_id: new_tutor_id).first&.group_id
        end
        column :course_user_id do
          store.get(V1::UserCourse.table_name, old.std_course_id)
        end
        column :role do
          :normal
        end
        column :creator_id do
          User.system.id
        end
        column :updater_id do
          User.system.id
        end
        column :updated_at
        column :created_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end


# Schema
#
# V2:
# create_table "course_groups", force: :cascade do |t|
#   t.integer  "course_id",  :null=>false, :index=>{:name=>"fk__course_groups_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_groups_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "name",       :limit=>255, :null=>false
#   t.integer  "creator_id", :null=>false, :index=>{:name=>"fk__course_groups_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_groups_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id", :null=>false, :index=>{:name=>"fk__course_groups_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_groups_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at", :null=>false
#   t.datetime "updated_at", :null=>false
# end
# add_index "course_groups", ["course_id", "name"], :name=>"index_course_groups_on_course_id_and_name", :unique=>true
#
# create_table "course_group_users", force: :cascade do |t|
#   t.integer  "group_id",       :null=>false, :index=>{:name=>"fk__course_group_users_course_group_id"}, :foreign_key=>{:references=>"course_groups", :name=>"fk_course_group_users_course_group_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "course_user_id", :null=>false, :index=>{:name=>"fk__course_group_users_course_user_id"}, :foreign_key=>{:references=>"course_users", :name=>"fk_course_group_users_course_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "role",           :null=>false
#   t.integer  "creator_id",     :null=>false, :index=>{:name=>"fk__course_group_users_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_group_users_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",     :null=>false, :index=>{:name=>"fk__course_group_users_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_group_users_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",     :null=>false
#   t.datetime "updated_at",     :null=>false
# end
# add_index "course_group_users", ["course_user_id", "group_id"], :name=>"index_course_group_users_on_course_user_id_and_course_group_id", :unique=>true

# V1
# create_table "tutorial_groups", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "std_course_id"
#   t.integer  "tut_course_id"
#   t.datetime "created_at",    :null => false
#   t.datetime "updated_at",    :null => false
# end
#
# add_index "tutorial_groups", ["course_id"], :name => "index_tutorial_groups_on_course_id"
# add_index "tutorial_groups", ["std_course_id", "tut_course_id"], :name => "index_tutorial_groups_on_std_course_id_and_tut_course_id", :unique => true
