def transform_levels(course_ids = [])
  transform_table :levels,
                  to: ::Course::Level,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :course_id, to: :course_id do |course_id|
      V1::Source::Course.transform(course_id)
    end
    column :exp_threshold, to: :experience_points_threshold
    column :updated_at, null: false
    column :created_at, null: false

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_levels", force: :cascade do |t|
#   t.integer  "course_id",                   null: false, index: {name: "fk__course_levels_course_id"}, foreign_key: {references: "courses", name: "fk_course_levels_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "experience_points_threshold", null: false
#   t.datetime "created_at",                  null: false
#   t.datetime "updated_at",                  null: false
# end

# V1
# create_table "levels", :force => true do |t|
#   t.integer  "level"
#   t.integer  "exp_threshold"
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.datetime "created_at",    :null => false
#   t.datetime "updated_at",    :null => false
# end