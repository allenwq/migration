class ForumSubscriptionTable < BaseTable
  table_name 'forum_forum_subscriptions'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Forum::Subscription.new

      migrate(old, new) do
        column :forum_id do
          store.get(V1::ForumForum.table_name, old.forum_id)
        end
        column :user_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class ForumTopicSubscriptionTable < BaseTable
  table_name 'forum_topic_subscriptions'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Discussion::Topic::Subscription.new

      migrate(old, new) do
        column :topic_id do
          forum_topic = Course::Forum::Topic.find(store.get(V1::ForumTopic.table_name, old.topic_id))
          forum_topic.discussion_topic.id
        end
        column :user_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class CommentSubscriptionTable < BaseTable
  table_name 'comment_subscriptions'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Discussion::Topic::Subscription.new

      submission_question_id = store.get(V1::CommentTopic.table_name, old.comment_topic_id)
      unless submission_question_id
        logger.log "Skipping #{old.class.name} #{old.id}: CommentTopic #{old.comment_topic_id} not found in store."
        next
      end

      migrate(old, new) do
        column :topic_id do
          submission_question = Course::Assessment::SubmissionQuestion.find(submission_question_id)
          submission_question.discussion_topic.id
        end
        column :user_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# v2
# create_table "course_forum_subscriptions", force: :cascade do |t|
#   t.integer "forum_id", :null=>false, :index=>{:name=>"fk__course_forum_subscriptions_forum_id"}, :foreign_key=>{:references=>"course_forums", :name=>"fk_course_forum_subscriptions_forum_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer "user_id",  :null=>false, :index=>{:name=>"fk__course_forum_subscriptions_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_forum_subscriptions_user_id", :on_update=>:no_action, :on_delete=>:no_action}
# end
# add_index "course_forum_subscriptions", ["forum_id", "user_id"], :name=>"index_course_forum_subscriptions_on_forum_id_and_user_id", :unique=>true
#
# create_table "course_discussion_topic_subscriptions", force: :cascade do |t|
#   t.integer "topic_id", :null=>false, :index=>{:name=>"fk__course_discussion_topic_subscriptions_topic_id"}, :foreign_key=>{:references=>"course_discussion_topics", :name=>"fk_course_discussion_topic_subscriptions_topic_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer "user_id",  :null=>false, :index=>{:name=>"fk__course_discussion_topic_subscriptions_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_discussion_topic_subscriptions_user_id", :on_update=>:no_action, :on_delete=>:no_action}
# end
# add_index "course_discussion_topic_subscriptions", ["topic_id", "user_id"], :name=>"index_topic_subscriptions_on_topic_id_and_user_id", :unique=>true
#
#
# V1
# create_table "comment_subscriptions", :force => true do |t|
#   t.integer  "topic_id"
#   t.string   "topic_type" # topic_type => {"Assessment::Answer"=>887, "Assessment::Question"=>4, "Mcq"=>3, "StdCodingAnswer"=>2, nil=>114173}
#   t.integer  "course_id"
#   t.integer  "user_course_id"
#   t.datetime "created_at",       :null => false
#   t.datetime "updated_at",       :null => false
#   t.integer  "comment_topic_id"
# end
# add_index "comment_subscriptions", ["comment_topic_id"], :name => "index_comment_subscriptions_on_comment_topic_id"
# add_index "comment_subscriptions", ["course_id"], :name => "index_comment_subscriptions_on_course_id"
# add_index "comment_subscriptions", ["topic_id", "topic_type"], :name => "index_comment_subscriptions_on_topic_id_and_topic_type"
# add_index "comment_subscriptions", ["user_course_id"], :name => "index_comment_subscriptions_on_user_course_id"
#
# create_table "forum_forum_subscriptions", :force => true do |t|
#   t.integer "forum_id"
#   t.integer "user_id"
# end
# add_index "forum_forum_subscriptions", ["forum_id"], :name => "index_forum_forum_subscriptions_on_forum_id"
# add_index "forum_forum_subscriptions", ["user_id"], :name => "index_forum_forum_subscriptions_on_user_id"
#
# create_table "forum_topic_subscriptions", :force => true do |t|
#   t.integer "topic_id"
#   t.integer "user_id"
# end
# add_index "forum_topic_subscriptions", ["topic_id"], :name => "index_forum_topic_subscriptions_on_topic_id"
# add_index "forum_topic_subscriptions", ["user_id"], :name => "index_forum_topic_subscriptions_on_user_id"
