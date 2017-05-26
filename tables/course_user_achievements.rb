class UserAchievementTable < BaseTable
  table_name 'user_achievements'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::UserAchievement.new

      migrate(old, new) do
        column :course_user_id do
          store.get(V1::UserCourse.table_name, old.user_course_id)
        end
        column :achievement_id do
          store.get(V1::Achievement.table_name, old.achievement_id)
        end
        column :obtained_at
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
# create_table "course_user_achievements", force: :cascade do |t|
#   t.integer  "course_user_id", index: {name: "fk__course_user_achievements_course_user_id"}, foreign_key: {references: "course_users", name: "fk_course_user_achievements_course_user_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "achievement_id", index: {name: "fk__course_user_achievements_achievement_id"}, foreign_key: {references: "course_achievements", name: "fk_course_user_achievements_achievement_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "obtained_at",    null: false
#   t.datetime "created_at",     null: false
#   t.datetime "updated_at",     null: false
# end

# V1
# create_table "user_achievements", :force => true do |t|
#   t.integer  "user_course_id"
#   t.integer  "achievement_id"
#   t.datetime "created_at",     :null => false
#   t.datetime "updated_at",     :null => false
#   t.datetime "obtained_at"
# end