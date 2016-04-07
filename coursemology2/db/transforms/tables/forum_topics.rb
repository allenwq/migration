def transform_forum_topics(course_ids = [])
  transform_table :forum_topics,
                  to: ::Course::Forum::Topic,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :forum_id do
      CoursemologyV1::Source::ForumForum.transform(source_record.forum_id)
    end
    column :title
    column :locked
    column :hidden
    column to: :topic_type do
      source_record.transform_topic_type
    end
    column to: :creator_id do
      result = source_record.transform_creator_id
      self.updater_id = result
      result
    end
    column :created_at
    column :updated_at

    skip_saving_unless_valid
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
#   t.integer "actable_id"
#   t.string  "actable_type", limit: 255, index: {name: "index_course_discussion_topics_on_actable_type_and_actable_id", with: ["actable_id"], unique: true}
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