module V1
  def_model 'forum_forum_subscriptions' do
    belongs_to :forum, class_name: 'ForumForum', inverse_of: nil
    belongs_to :user_course, foreign_key: :user_id, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:forum).where(forum: { course_id: Array(course_ids) })
    end
  end

  def_model 'forum_topic_subscriptions' do
    belongs_to :topic, class_name: 'ForumTopic', inverse_of: nil
    belongs_to :user_course, foreign_key: :user_id, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(topic: :forum).
        where(topic: { forum: { course_id: Array(course_ids) } })
    end
  end

  def_model 'comment_subscriptions' do
    belongs_to :comment_topic, inverse_of: nil
    belongs_to :course, inverse_of: nil
    belongs_to :user_course, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:comment_topic).
        where(course_id: Array(course_ids)).
        where(comment_topics: { topic_type: 'Assessment::Answer'})
    end
  end
end
