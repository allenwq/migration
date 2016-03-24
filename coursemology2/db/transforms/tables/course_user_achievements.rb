def transform_course_user_achievements(course_ids = [])
  transform_table :user_achievements, to: ::Course::UserAchievement,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :course_user_id do
      CoursemologyV1::Source::UserCourse.transform(source_record.user_course_id)
    end
    column to: :achievement_id do
      CoursemologyV1::Source::Achievement.transform(source_record.achievement_id)
    end
    column :obtained_at
    column :created_at
    column :updated_at

    skip_saving_unless_valid
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