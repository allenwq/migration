def transform_assessment_tabs(course_ids = [])
  transform_table :tabs,
                  to: ::Course::Assessment::Tab,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :title
    column :pos, to: :weight do |pos|
      pos || 1
    end
    column to: :category_id do
      new_course = Course.find(V1::Source::Course.transform(source_record.course_id))
      raise 'Category count invalid' if new_course.assessment_categories.count != 2

      if source_record.owner_type == 'Assessment::Training'
        # TODO: This is a hack for deleting the default category
        # Unscope weight
        new_course.assessment_categories.unscope(:order).first.tabs.where(title: 'Default').delete_all
        new_course.assessment_categories.unscope(:order).first.id
      else
        new_course.assessment_categories.unscope(:order).last.tabs.where(title: 'Default').delete_all
        new_course.assessment_categories.unscope(:order).last.id
      end
    end

    column :updated_at, null: false
    column :created_at, null: false

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_assessment_tabs", force: :cascade do |t|
#   t.integer  "category_id", null: false, index: {name: "fk__course_assessment_tabs_category_id"}, foreign_key: {references: "course_assessment_categories", name: "fk_course_assessment_tabs_category_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",       limit: 255, null: false
#   t.integer  "weight",      null: false
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_assessment_tabs_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessment_tabs_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_assessment_tabs_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessment_tabs_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end

# V1
# create_table "tabs", :force => true do |t|
#   t.integer  "course_id",   :null => false
#   t.string   "title",       :null => false
#   t.text     "description"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
#   t.string   "owner_type",  :null => false
#   t.integer  "pos"
#   t.datetime "deleted_at"
# end
