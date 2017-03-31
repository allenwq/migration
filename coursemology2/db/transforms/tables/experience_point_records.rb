def transform_manual_exp(course_ids = [])
  transform_table :exp_transactions,
                  to: ::Course::ExperiencePointsRecord,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :exp, to: :points_awarded
    column to: :reason do
      source_record.reason || '( No Reason )'
    end
    column to: :course_user_id do
      V1::Source::UserCourse.transform(source_record.user_course_id)
    end
    column to: :creator_id do
      result = V1::Source::Course.transform(source_record.giver_id)
      self.updater_id = result
      result
    end
    column to: :updater_id do
      V1::Source::Course.transform(source_record.giver_id)
    end

    column :created_at
    column :updated_at
    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
#
# create_table "course_experience_points_records", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",   limit: 255, index: {name: "index_course_experience_points_records_on_actable", with: ["actable_id"], unique: true}
#   t.integer  "points_awarded"
#   t.integer  "course_user_id", null: false, index: {name: "fk__course_experience_points_records_course_user_id"}, foreign_key: {references: "course_users", name: "fk_course_experience_points_records_course_user_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "reason",         limit: 255
#   t.integer  "creator_id",     null: false, index: {name: "fk__course_experience_points_records_creator_id"}, foreign_key: {references: "users", name: "fk_course_experience_points_records_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",     null: false, index: {name: "fk__course_experience_points_records_updater_id"}, foreign_key: {references: "users", name: "fk_course_experience_points_records_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",     null: false
#   t.datetime "updated_at",     null: false
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
