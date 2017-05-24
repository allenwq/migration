class AssessmentTabTable < BaseTable
  table_name 'tabs'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = Course::Assessment::Tab.new
      migrate(old, new) do
        column :title
        column :weight do
          old.pos || 1
        end
        column :category_id do
          new_course = ::Course.find(store.get(V1::Course.table_name, old.course_id))
          raise 'Category count invalid' if new_course.assessment_categories.count != 2

          # Delete the default tabs because when the code goes here there's at least 1 tab.
          if old.owner_type == 'Assessment::Training'
            # Unscope weight
            new_course.assessment_categories.unscope(:order).first.tabs.where(title: 'Default').delete_all
            new_course.assessment_categories.unscope(:order).first.id
          else
            old.assessment_categories.unscope(:order).last.tabs.where(title: 'Default').delete_all
            old.assessment_categories.unscope(:order).last.id
          end
        end

        column :updated_at
        column :created_at

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id) if new.persisted?
      end
    end
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
