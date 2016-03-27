def transform_assessments(course_ids = [])
  transform_table :assessments, to: ::Course::Assessment,
                                default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column :course_id, to: :course_id, null: false do |old_course_id|
      CoursemologyV1::Source::Course.transform(old_course_id)
    end
    column :title
    column :description
    column :exp, to: :base_exp do |exp|
      exp || 0
    end
    column :bonus_exp, to: :time_bonus_exp do |bonus_exp|
      bonus_exp || 0
    end
    column to: :extra_bonus_exp do
      0
    end
    column :open_at, to: :start_at
    column :close_at, to: :end_at
    column :bonus_cutoff_at, to: :bonus_end_at
    column :published, to: :draft do |published|
      !published
    end
    column to: :display_mode do
      if source_record.as_assessment_type == 'Assessment::Training'
        :guided
      elsif source_record.as_assessment_type == 'Assessment::Mission'
        :worksheet
      end
    end
    column to: :tab_id do
      assessment_infer_new_tab_id(source_record, self)
    end
    column :creator_id, to: :creator_id do |creator_id|
      CoursemologyV1::Source::User.transform(creator_id)
    end

    column :file_uploads do |file_uploads|
      file_uploads.visible.each do |file|
        attachment = file.transform_attachment_reference
        folder.materials.build(attachment_reference: attachment, name: attachment.name)
      end
    end
    column :updated_at, null: false
    column :created_at, null: false

    skip_saving_unless_valid
  end
end

def assessment_infer_new_tab_id(old, new)
  # Some assessment has a tab id of 0...
  return CoursemologyV1::Source::Tab.transform(old.tab_id) if old.tab_id && old.tab_id > 0

  # Try to assign to default tab
  new_course = Course.find(CoursemologyV1::Source::Course.transform(old.course_id))
  # Training's category in the new course is the first, mission category is the second
  if old.as_assessment_type == 'Assessment::Training'
    new_course.assessment_categories.unscoped.first.tabs.first.id
  elsif old.as_assessment_type == 'Assessment::Mission'
    new_course.assessment_categories.unscoped.last.tabs.first.id
  end
end

# Schema
#
# V2:
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
# create_table "course_assessments", force: :cascade do |t|
#   t.integer  "tab_id",       null: false, index: {name: "fk__course_assessments_tab_id"}, foreign_key: {references: "course_assessment_tabs", name: "fk_course_assessments_tab_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "display_mode", default: 0, null: false
#   t.integer  "creator_id",   null: false, index: {name: "fk__course_assessments_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessments_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",   null: false, index: {name: "fk__course_assessments_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessments_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",   null: false
#   t.datetime "updated_at",   null: false
# end

# V1
# create_table "assessments", :force => true do |t|
#   t.integer  "as_assessment_id",                     :null => false
#   t.string   "as_assessment_type",                   :null => false
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.integer  "tab_id"
#   t.string   "title"
#   t.text     "description"
#   t.integer  "position"
#   t.integer  "exp"
#   t.float    "max_grade"
#   t.boolean  "published"
#   t.boolean  "comment_per_qn",     :default => true
#   t.integer  "display_mode_id"
#   t.integer  "bonus_exp"
#   t.datetime "bonus_cutoff_at"
#   t.datetime "open_at"
#   t.datetime "close_at"
#   t.datetime "deleted_at"
#   t.datetime "created_at",                           :null => false
#   t.datetime "updated_at",                           :null => false
# end
# create_table "assessment_missions", :force => true do |t|
#   t.boolean  "file_submission",      :default => false
#   t.boolean  "file_submission_only", :default => false
#   t.datetime "deleted_at"
#   t.datetime "created_at",                              :null => false
#   t.datetime "updated_at",                              :null => false
# end
#
# create_table "assessment_trainings", :force => true do |t|
#   t.boolean  "skippable"
#   t.datetime "deleted_at"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end