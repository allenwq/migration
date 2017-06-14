class ForumTopicTable < BaseTable
  table_name 'forum_topics'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Forum::Topic.new
      
      migrate(old, new) do
        column :forum_id do
          store.get(V1::ForumForum.table_name, old.forum_id)
        end
        column :course_id do
          store.get(V1::Course.table_name, old.forum.try(:course_id))
        end
        column :title
        column :locked
        column :hidden
        column :topic_type do
          old.transform_topic_type
        end
        column :creator_id do
          result = old.transform_creator_id(store)
          new.updater_id = result
          result
        end
        column :created_at
        column :updated_at
        new.discussion_topic.created_at = old.created_at
        new.discussion_topic.updated_at = old.updated_at

        skip_saving_unless_valid
        old.migrate_seen_by_users(store, logger, new)

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_forum_topics", force: :cascade do |t|
#   t.integer  "forum_id",   null: false, index: {name: "fk__course_forum_topics_forum_id"}, foreign_key: {references: "course_forums", name: "fk_course_forum_topics_forum_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",      limit: 255,                 null: false
#   t.string   "slug",       limit: 255
#   t.boolean  "locked",     default: false
#   t.boolean  "hidden",     default: false
#   t.integer  "topic_type", default: 0
#   t.integer  "creator_id", null: false, index: {name: "fk__course_forum_topics_creator_id"}, foreign_key: {references: "users", name: "fk_course_forum_topics_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id", null: false, index: {name: "fk__course_forum_topics_updater_id"}, foreign_key: {references: "users", name: "fk_course_forum_topics_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end
#
# create_table "course_discussion_topics", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",        :limit=>255, :index=>{:name=>"index_course_discussion_topics_on_actable_type_and_actable_id", :with=>["actable_id"], :unique=>true}
#   t.integer  "course_id",           :null=>false, :index=>{:name=>"fk__course_discussion_topics_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_discussion_topics_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.boolean  "pending_staff_reply", :default=>false, :null=>false
#   t.datetime "created_at",          :null=>false
#   t.datetime "updated_at",          :null=>false
# end
# create_table "course_discussion_topic_subscriptions", force: :cascade do |t|
#   t.integer "topic_id", null: false, index: {name: "fk__course_discussion_topic_subscriptions_topic_id"}, foreign_key: {references: "course_discussion_topics", name: "fk_course_discussion_topic_subscriptions_topic_id", on_update: :no_action, on_delete: :no_action}
#   t.integer "user_id",  null: false, index: {name: "fk__course_discussion_topic_subscriptions_user_id"}, foreign_key: {references: "users", name: "fk_course_discussion_topic_subscriptions_user_id", on_update: :no_action, on_delete: :no_action}
# end
#
# create_table "course_forum_topic_views", force: :cascade do |t|
#   t.integer  "topic_id",   null: false, index: {name: "fk__course_forum_topic_views_topic_id"}, foreign_key: {references: "course_forum_topics", name: "fk_course_forum_topic_views_topic_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "user_id",    null: false, index: {name: "fk__course_forum_topic_views_user_id"}, foreign_key: {references: "users", name: "fk_course_forum_topic_views_user_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end

# V1
#
# create_table "forum_topics", :force => true do |t|
#   t.integer  "forum_id"
#   t.string   "title"
#   t.string   "cached_slug"
#   t.integer  "author_id"
#   t.boolean  "locked",      :default => false
#   t.boolean  "hidden",      :default => false
#   t.integer  "topic_type",  :default => 0
#   t.datetime "created_at",                     :null => false
#   t.datetime "updated_at",                     :null => false
# end
#
# create_table "forum_topic_subscriptions", :force => true do |t|
#   t.integer "topic_id"
#   t.integer "user_id"
# end
#
# create_table "forum_topic_views", :force => true do |t|
#   t.integer  "topic_id"
#   t.integer  "user_id"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end