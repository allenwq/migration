def transform_course_users(course_ids = [])
  transform_table :user_courses, to: ::CourseUser,
                                 default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column :user_id, to: :user_id do |user_id|
      CoursemologyV1::Source::User.transform(user_id)
    end
    column :course_id, to: :course_id do |course_id|
      CoursemologyV1::Source::Course.transform(course_id)
    end
    column :name
    column :is_phantom, to: :phantom
    column :role_id, to: :role do |role_id|
      case role_id
      when 3
        :owner
      when 4
        :teaching_assistant
      else
        :student
      end
    end
    column to: :workflow_state do
      'approved'
    end
    column :last_active_time, to: :last_active_at
    column :updated_at, null: false
    column :created_at, null: false

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_users", force: :cascade do |t|
#   t.integer  "course_id",      null: false, index: {name: "fk__course_users_course_id"}, foreign_key: {references: "courses", name: "fk_course_users_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "user_id",        index: {name: "fk__course_users_user_id"}, foreign_key: {references: "users", name: "fk_course_users_user_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "workflow_state", limit: 255,                 null: false
#   t.integer  "role",           default: 0,     null: false
#   t.string   "name",           limit: 255,                 null: false
#   t.boolean  "phantom",        default: false, null: false
#   t.datetime "last_active_at"
#   t.datetime "created_at",     null: false
#   t.datetime "updated_at",     null: false
#   t.integer  "creator_id",     null: false, index: {name: "fk__course_users_creator_id"}, foreign_key: {references: "users", name: "fk_course_users_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",     null: false, index: {name: "fk__course_users_updater_id"}, foreign_key: {references: "users", name: "fk_course_users_updater_id", on_update: :no_action, on_delete: :no_action}
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