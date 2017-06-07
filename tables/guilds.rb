class GuildTable < BaseTable
  table_name 'guilds'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Group.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name
        # TODO: Add description
        #column :description
        column :creator_id do
          User::SYSTEM_USER_ID
        end
        column :updater_id do
          User::SYSTEM_USER_ID
        end
        column :updated_at
        column :created_at

        # Skip group user validation
        new.save(validate: false)
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class GuildUserTable < BaseTable
  table_name 'guild_users'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::GroupUser.new

      migrate(old, new) do
        column :group_id do
          store.get(V1::Guild.table_name, old.guild_id)
        end
        column :course_user_id do
          store.get(V1::UserCourse.table_name, old.user_course_id)
        end
        column :role do
          :normal
        end
        column :creator_id do
          User::SYSTEM_USER_ID
        end
        column :updater_id do
          User::SYSTEM_USER_ID
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
# create_table "guild_users", :force => true do |t|
#   t.integer  "role_id". Role is not used in v1
#   t.integer  "user_course_id"
#   t.integer  "guild_id"
#   t.datetime "created_at",     :null => false
#   t.datetime "updated_at",     :null => false
# end
#
# create_table "guilds", :force => true do |t|
#   t.string   "name"
#   t.text     "description"
#   t.integer  "course_id"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
# end