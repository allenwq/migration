class ForumPostVoteTable < BaseTable
  table_name 'votes'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Discussion::Post::Vote.new

      migrate(old, new) do
        column :post_id do
          store.get(V1::ForumPost.table_name, old.votable_id)
        end
        column :vote_flag
        column :creator_id do
          result = store.get(V1::User.table_name, old.voter_id)
          new.updater_id = result
          result
        end
        column :created_at
        column :updated_at

        # Drop those records without creator
        if new.creator_id.present?
          skip_saving_unless_valid
          store.set(model.table_name, old.id, new.id)
        else
          logger.log("#{old.class.name} #{old.id}: creator is nil")
        end
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