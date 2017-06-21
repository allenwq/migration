class LessonPlanEventMaterialTable < BaseTable
  table_name 'lesson_plan_resources'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::LessonPlan::EventMaterial.new

      migrate(old, new) do
        column :lesson_plan_event_id do
          store.get(V1::LessonPlanEntry.table_name, old.lesson_plan_entry_id)
        end
        column :material_id do
          store.get(V1::Material.table_name, old.obj_id)
        end

        if new.material_id.blank?
          # There are records point to the material in other courses, material_id is nil in this case...
          logger.log "Invalid #{old.class} #{old.id}: material_id is nil"
        else
          skip_saving_unless_valid
        end

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_lesson_plan_event_materials", force: :cascade do |t|
#   t.integer "lesson_plan_event_id", :null=>false, :index=>{:name=>"fk__course_lesson_plan_event_materials_lesson_plan_event_id"}, :foreign_key=>{:references=>"course_lesson_plan_events", :name=>"fk_course_lesson_plan_event_materials_lesson_plan_event_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer "material_id",          :null=>false, :index=>{:name=>"fk__course_lesson_plan_event_materials_material_id"}, :foreign_key=>{:references=>"course_materials", :name=>"fk_course_lesson_plan_event_materials_material_id", :on_update=>:no_action, :on_delete=>:no_action}
# end

# V1
# create_table "lesson_plan_resources", :force => true do |t|
#   t.integer "lesson_plan_entry_id"
#   t.integer "obj_id"
#   t.string  "obj_type", currently obj_type is only 'Material'
# end