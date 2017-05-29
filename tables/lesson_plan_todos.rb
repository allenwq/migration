class LessonPlanTodoTable < BaseTable
  table_name 'pending_actions'
  scope { |ids| within_courses(ids).includes(:user_course) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::LessonPlan::Todo.new

      migrate(old, new) do
        column :item_id do
          old.target_item_id(store)
        end
        column :user_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end
        column :workflow_state do
          # ["not_started", "in_progress", "completed"]
          old.target_workflow_state(store)
        end

        column :is_ignored => :ignore
        column :creator_id do
          old.target_item(store).try(:creator_id)
        end
        column :updater_id do
          new.user_id
        end
        column :updated_at
        column :created_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_lesson_plan_todos", force: :cascade do |t|
#   t.integer  "item_id",        :null=>false, :index=>{:name=>"fk__course_lesson_plan_todos_item_id"}, :foreign_key=>{:references=>"course_lesson_plan_items", :name=>"fk_course_lesson_plan_todos_item_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "user_id",        :null=>false, :index=>{:name=>"fk__course_lesson_plan_todos_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_lesson_plan_todos_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "workflow_state", :limit=>255, :null=>false
#   t.boolean  "ignore",         :default=>false, :null=>false
#   t.integer  "creator_id",     :null=>false, :index=>{:name=>"fk__course_lesson_plan_todos_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_lesson_plan_todos_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",     :null=>false, :index=>{:name=>"fk__course_lesson_plan_todos_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_lesson_plan_todos_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end
# add_index "course_lesson_plan_todos", ["item_id", "user_id"], :name=>"index_course_lesson_plan_todos_on_item_id_and_user_id", :unique=>true

# V1
# create_table "pending_actions", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "user_course_id"
#   t.integer  "item_id"
#   t.string   "item_type"
#   t.boolean  "is_ignored",     :default => false
#   t.boolean  "is_done",        :default => false
#   t.datetime "created_at",                        :null => false
#   t.datetime "updated_at",                        :null => false
# end