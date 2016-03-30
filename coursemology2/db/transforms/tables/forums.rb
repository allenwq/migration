def transform_forums(course_ids = [])
  transform_table :forum_forums,
                  to: ::Course::Forum,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column :name
    column :description

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_forums", force: :cascade do |t|
#   t.integer  "course_id",   null: false, index: {name: "fk__course_forums_course_id"}, foreign_key: {references: "courses", name: "fk_course_forums_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "name",        limit: 255, null: false
#   t.string   "slug",        limit: 255
#   t.text     "description"
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_forums_creator_id"}, foreign_key: {references: "users", name: "fk_course_forums_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_forums_updater_id"}, foreign_key: {references: "users", name: "fk_course_forums_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end
#
# create_table "course_forum_subscriptions", force: :cascade do |t|
#   t.integer "forum_id", null: false, index: {name: "fk__course_forum_subscriptions_forum_id"}, foreign_key: {references: "course_forums", name: "fk_course_forum_subscriptions_forum_id", on_update: :no_action, on_delete: :no_action}
#   t.integer "user_id",  null: false, index: {name: "fk__course_forum_subscriptions_user_id"}, foreign_key: {references: "users", name: "fk_course_forum_subscriptions_user_id", on_update: :no_action, on_delete: :no_action}
# end

# V1:
#
# create_table "forum_forums", :force => true do |t|
#   t.integer "course_id"
#   t.string  "name"
#   t.string  "cached_slug"
#   t.text    "description"
#   t.boolean "locked",      :default => false
# end
#
# create_table "forum_forum_subscriptions", :force => true do |t|
#   t.integer "forum_id"
#   t.integer "user_id"
# end
