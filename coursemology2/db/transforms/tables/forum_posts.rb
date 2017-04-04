def transform_forum_posts(course_ids = [])
  transform_table :forum_posts,
                  to: ::Course::Discussion::Post,
                  default_scope: proc { V1::Source::ForumPost.tsort(within_courses(course_ids)) } do
    primary_key :id
    column to: :parent_id do
      dst_id = V1::Source::ForumPost.transform(source_record.parent_id)
      if source_record.parent_id && !dst_id
        puts "Cannot find parent for #{source_record.class.name} #{source_record.id}"
      end

      dst_id
    end
    column to: :topic_id do
      V1::Source::ForumTopic.transform(source_record.topic_id)
    end
    column :title
    column to: :text do
      text = ContentParser.parse_mc_tags(source_record.text)
      text, references = ContentParser.parse_images(source_record, text)
      self.attachment_references = references if references.any?
      text
    end
    column to: :creator_id do
      result = source_record.transform_creator_id
      self.updater_id = result
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