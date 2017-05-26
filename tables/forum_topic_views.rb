class ForumTopicViewTable < BaseTable
  table_name 'forum_topic_views'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Forum::Topic::View.new

      migrate(old, new) do
        column :topic_id do
          store.get(V1::ForumTopic.table_name, old.topic_id)
        end
        column :user_id do
          dst_course_user_id = store.get(V1::UserCourse.table_name, old.user_id)
          ::CourseUser.find_by(id: dst_course_user_id).try(:user_id) || ::User::DELETED_USER_ID
        end
        column :created_at
        column :updated_at

        skip_saving_unless_valid do
          # Improve performance
          if topic_id && user_id
            true
          else
            valid?
          end
        end
        
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
#
# create_table "course_forum_topic_views", force: :cascade do |t|
#   t.integer  "topic_id",   null: false, index: {name: "fk__course_forum_topic_views_topic_id"}, foreign_key: {references: "course_forum_topics", name: "fk_course_forum_topic_views_topic_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "user_id",    null: false, index: {name: "fk__course_forum_topic_views_user_id"}, foreign_key: {references: "users", name: "fk_course_forum_topic_views_user_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end

# V1
#
# create_table "forum_topic_views", :force => true do |t|
#   t.integer  "topic_id"
#   t.integer  "user_id" # This points to the user_course actually
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end