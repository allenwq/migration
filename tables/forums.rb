class ForumTable < BaseTable
  table_name 'forum_forums'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Forum.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name
        column :description

        column :created_at do
          Time.zone.now
        end

        column :updated_at do
          Time.zone.now
        end

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id)
      end
    end
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
