def transform_conditions(course_ids = [])
  transform_table :requirements,
                  to: ::Course::Condition,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :conditional do
      dst_id = V1::Source::Achievement.transform(source_record.obj_id)
      ::Course::Achievement.find_by(id: dst_id)
    end
    column to: :course_id do
      conditional.course_id if conditional
    end
    column to: :actable do
      actable = source_record.transform_actable
      actable.condition = self
      actable
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end

  transform_table :assessment_dependency,
                  to: ::Course::Condition::Assessment,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :conditional_type do
      ::Course::Assessment.name
    end
    column to: :conditional_id do
      V1::Source::Assessment.transform(source_record.id)
    end
    column to: :course_id do
      conditional.course_id
    end
    column to: :assessment_id do
      # The id points to the assessment id.
      V1::Source::Assessment.transform(source_record.dependent_id)
    end
    column to: :minimum_grade_percentage do
      # Only require to finish the dependent one.
      nil
    end

    column to: :created_at do
      Time.zone.now
    end
    column to: :updated_at do
      Time.zone.now
    end

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_condition_achievements", force: :cascade do |t|
#   t.integer "achievement_id", null: false, index: {name: "fk__course_condition_achievements_achievement_id"}, foreign_key: {references: "course_achievements", name: "fk_course_condition_achievements_achievement_id", on_update: :no_action, on_delete: :no_action}
# end
#
# create_table "course_condition_assessments", force: :cascade do |t|
#   t.integer "assessment_id",            null: false, index: {name: "fk__course_condition_assessments_assessment_id"}, foreign_key: {references: "course_assessments", name: "fk_course_condition_assessments_assessment_id", on_update: :no_action, on_delete: :no_action}
#   t.float   "minimum_grade_percentage"
# end
#
# create_table "course_condition_levels", force: :cascade do |t|
#   t.integer "minimum_level", null: false
# end
#
# create_table "course_conditions", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",     limit: 255, index: {name: "index_course_conditions_on_actable_type_and_actable_id", with: ["actable_id"], unique: true}
#   t.integer  "course_id",        null: false, index: {name: "fk__course_conditions_course_id"}, foreign_key: {references: "courses", name: "fk_course_conditions_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "conditional_id",   null: false
#   t.string   "conditional_type", limit: 255, null: false, index: {name: "index_course_conditions_on_conditional_type_and_conditional_id", with: ["conditional_id"]}
#   t.integer  "creator_id",       null: false, index: {name: "fk__course_conditions_creator_id"}, foreign_key: {references: "users", name: "fk_course_conditions_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",       null: false, index: {name: "fk__course_conditions_updater_id"}, foreign_key: {references: "users", name: "fk_course_conditions_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",       null: false
#   t.datetime "updated_at",       null: false
# end

# V1
# create_table "requirements", :force => true do |t|
#   t.integer  "req_id"
#   t.string   "req_type"
#   t.integer  "obj_id"
#   t.string   "obj_type"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end
#
# create_table "asm_reqs", :force => true do |t|
#   t.integer  "asm_id"
#   t.string   "asm_type"
#   t.integer  "min_grade"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end
#
# create_table "assessment_dependency", :id => false, :force => true do |t|
#   t.integer "id",           :default => 0, :null => false  This id points to the one that depends on others
#   t.integer "dependent_id"
# end