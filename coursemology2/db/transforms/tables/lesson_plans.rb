def transform_lesson_plans(course_ids = [])
  transform_table :lesson_plan_milestones, to: ::Course::LessonPlan::Milestone,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column :title
    column :description
    column :start_at
    column :creator_id

    skip_saving_unless_valid
  end

  transform_table :lesson_plan_entries, to: ::Course::LessonPlan::Event,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column to: :event_type do
      source_record.transform_entry_type
    end
    column :title
    column :description
    column :location
    column :start_at
    column :end_at
    column to: :draft do
      false
    end
    column :creator_id

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_lesson_plan_events", force: :cascade do |t|
#   t.string  "location",   limit: 255
#   t.integer "event_type", default: 0, null: false
# end
#
# create_table "course_lesson_plan_items", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",    limit: 255, index: {name: "index_course_lesson_plan_items_on_actable_type_and_actable_id", with: ["actable_id"], unique: true}
#   t.integer  "course_id",       null: false, index: {name: "fk__course_lesson_plan_items_course_id"}, foreign_key: {references: "courses", name: "fk_course_lesson_plan_items_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",           limit: 255,                 null: false
#   t.text     "description"
#   t.boolean  "draft",           default: false, null: false
#   t.integer  "base_exp",        null: false
#   t.integer  "time_bonus_exp",  null: false
#   t.integer  "extra_bonus_exp", null: false
#   t.datetime "start_at",        null: false
#   t.datetime "bonus_end_at"
#   t.datetime "end_at"
#   t.integer  "creator_id",      null: false, index: {name: "fk__course_lesson_plan_items_creator_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_items_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",      null: false, index: {name: "fk__course_lesson_plan_items_updater_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_items_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",      null: false
#   t.datetime "updated_at",      null: false
# end
#
# create_table "course_lesson_plan_milestones", force: :cascade do |t|
#   t.integer  "course_id",   index: {name: "fk__course_lesson_plan_milestones_course_id"}, foreign_key: {references: "courses", name: "fk_course_lesson_plan_milestones_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",       limit: 255, null: false
#   t.text     "description"
#   t.datetime "start_at",    null: false
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_lesson_plan_milestones_creator_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_milestones_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_lesson_plan_milestones_updater_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_milestones_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end

# V1
# create_table "lesson_plan_entries", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.string   "title"
#   t.integer  "entry_type"
#   t.text     "description"
#   t.datetime "start_at"
#   t.datetime "end_at"
#   t.string   "location"
# end
#
# create_table "lesson_plan_milestones", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.string   "title"
#   t.text     "description"
#   t.datetime "end_at"
#   t.datetime "start_at"
#   t.boolean  "is_publish",  :default => true
# end
#
# create_table "lesson_plan_resources", :force => true do |t|
#   t.integer "lesson_plan_entry_id"
#   t.integer "obj_id"
#   t.string  "obj_type"
# end