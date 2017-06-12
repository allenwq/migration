class ActivityTable < BaseTable
  table_name 'activities'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Notification.new
      new.notification_type = :feed
      activity = ::Activity.new
      activity.actor_id = old.target_actor_id(store)
      activity.object_type, activity.object_id = old.target_object(store)
      activity.notifier_type, activity.event = old.target_notifier_and_event
      activity.created_at = old.created_at
      activity.updated_at = old.updated_at
      if activity.valid?
        activity.save!
      else
        @logger.log "Invalid #{old.class} #{old.primary_key_value}: #{activity.errors.full_messages.to_sentence}"
        next
      end

      migrate(old, new) do
        column :activity do
          activity
        end
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :created_at
        column :updated_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_notifications", force: :cascade do |t|
#   t.integer  "activity_id",       :null=>false, :index=>{:name=>"index_course_notifications_on_activity_id"}, :foreign_key=>{:references=>"activities", :name=>"fk_course_notifications_activity_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "course_id",         :null=>false, :index=>{:name=>"index_course_notifications_on_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_notifications_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "notification_type", :default=>0, :null=>false
#   t.datetime "created_at",        :null=>false
#   t.datetime "updated_at",        :null=>false
# end
#
# create_table "activities", force: :cascade do |t|
#   t.integer  "actor_id",      :null=>false, :index=>{:name=>"fk__activities_actor_id"}, :foreign_key=>{:references=>"users", :name=>"fk_activities_actor_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "object_id",     :null=>false
#   t.string   "object_type",   :limit=>255, :null=>false
#   t.string   "event",         :limit=>255, :null=>false
#   t.string   "notifier_type", :limit=>255, :null=>false
#   t.datetime "created_at",    :null=>false
#   t.datetime "updated_at",    :null=>false
# end

# V1
# create_table "activities", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "actor_course_id"
#   t.integer  "target_course_id" comment: not used
#   t.integer  "action_id"
#   t.integer  "obj_id"
#   t.string   "obj_type"
#   t.string   "extra"  comment: not used
#   t.datetime "created_at",       :null => false
#   t.datetime "updated_at",       :null => false
#   t.string   "obj_url"
# end
#
# create_table "actions", :force => true do |t|
#   t.string   "text"
#   t.text     "description"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
# end
