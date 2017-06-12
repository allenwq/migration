class ForumPostTable < BaseTable
  table_name 'forum_posts'
  scope { |ids| V1::ForumPost.tsort(within_courses(ids)) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Discussion::Post.new
      migrate(old, new) do
        column :parent_id do
          dst_id = store.get(V1::ForumPost.table_name, old.parent_id)
          if old.parent_id && !dst_id
            Logger.log "Cannot find parent for #{old.class.name} #{old.id}"
          end

          dst_id
        end
        column :topic_id do
          id = store.get(V1::ForumTopic.table_name, old.topic_id)
          Course::Discussion::Topic.find_by(actable_id: id, actable_type: 'Course::Forum::Topic').try(:id)
        end
        column :title
        column :text do
          text = ContentParser.parse_mc_tags(old.text)
          text, references = ContentParser.parse_images(old, text)
          new.attachment_references = references if references.any?
          text
        end
        column :creator_id do
          result = old.transform_creator_id(store)
          new.updater_id = result
          result
        end
        column :created_at
        column :updated_at

        skip_saving_unless_valid do
          # Drop those records without creator
          if creator_id.present?
            valid?
          else
            errors.add(:creator, :blank)
            false
          end
        end
        old.migrate_seen_by_users(store, new)

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end


# Schema
#
# V2:
#
# create_table "course_discussion_posts", force: :cascade do |t|
#   t.integer  "parent_id",  index: {name: "fk__course_discussion_posts_parent_id"}, foreign_key: {references: "course_discussion_posts", name: "fk_course_discussion_posts_parent_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "topic_id",   null: false, index: {name: "fk__course_discussion_posts_topic_id"}, foreign_key: {references: "course_discussion_topics", name: "fk_course_discussion_posts_topic_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",      limit: 255, null: false
#   t.text     "text"
#   t.integer  "creator_id", null: false, index: {name: "fk__course_discussion_posts_creator_id"}, foreign_key: {references: "users", name: "fk_course_discussion_posts_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id", null: false, index: {name: "fk__course_discussion_posts_updater_id"}, foreign_key: {references: "users", name: "fk_course_discussion_posts_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end

# V1:
#
# create_table "forum_posts", :force => true do |t|
#   t.integer  "topic_id"
#   t.integer  "parent_id"
#   t.string   "title"
#   t.integer  "author_id"
#   t.boolean  "answer"
#   t.text     "text"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end
#
# create_table "forum_post_votes", :force => true do |t|
#   t.integer  "post_id"
#   t.integer  "vote"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end