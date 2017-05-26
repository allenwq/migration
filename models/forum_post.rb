module V1
  def_model 'forum_posts' do
    belongs_to :topic, class_name: 'ForumTopic', inverse_of: nil
    belongs_to :parent, class_name: 'ForumPost', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(topic: :forum).
        where(topic: { forum: { course_id: Array(course_ids) } }).
        includes(:parent)
    end

    # Sort the records so that parent is always migrated before child.
    def self.tsort(posts)
      result = posts
      result.instance_eval do
        extend TSort

        alias tsort_each_node each

        def tsort_each_child(node, &block)
          [node.parent].each(&block) if node.parent
        end
      end

      result.tsort
    end

    def transform_creator_id(store)
      # author id references to UserCourse
      dst_course_user_id = store.get(V1::UserCourse.table_name,  author_id)
      user_id = ::CourseUser.find_by(id: dst_course_user_id).try(:user_id)
      user_id || ::User::DELETED_USER_ID
    end
  end

  def_model 'votes' do
    scope :within_courses, ->(course_ids) do
      joins("INNER JOIN forum_posts ON forum_posts.id = votes.votable_id AND votes.votable_type = 'ForumPost'").
        joins('INNER JOIN forum_topics ON forum_posts.topic_id = forum_topics.id').
        joins('INNER JOIN forum_forums ON forum_forums.id = forum_topics.forum_id').
        where("forum_forums.course_id IN (#{Array(course_ids).join(', ')})")
    end
  end
end
