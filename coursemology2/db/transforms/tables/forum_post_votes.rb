def transform_forum_post_votes(course_ids = [])
  transform_table :votes,
                  to: ::Course::Discussion::Post::Vote,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :post_id do
      V1::Source::ForumPost.transform(source_record.votable_id)
    end
    column :vote_flag
    column to: :creator_id do
      result = V1::Source::User.transform(source_record.voter_id)
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
# create_table "course_discussion_post_votes", force: :cascade do |t|
#   t.integer  "post_id",    null: false, index: {name: "fk__course_discussion_post_votes_post_id"}, foreign_key: {references: "course_discussion_posts", name: "fk_course_discussion_post_votes_post_id", on_update: :no_action, on_delete: :no_action}
#   t.boolean  "vote_flag",  null: false
#   t.integer  "creator_id", null: false, index: {name: "fk__course_discussion_post_votes_creator_id"}, foreign_key: {references: "users", name: "fk_course_discussion_post_votes_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id", null: false, index: {name: "fk__course_discussion_post_votes_updater_id"}, foreign_key: {references: "users", name: "fk_course_discussion_post_votes_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end

# V1:
#
# create_table "votes", :force => true do |t|
#   t.integer  "votable_id"
#   t.string   "votable_type"
#   t.integer  "voter_id"
#   t.string   "voter_type"
#   t.boolean  "vote_flag"
#   t.string   "vote_scope"
#   t.datetime "created_at",   :null => false
#   t.datetime "updated_at",   :null => false
# end