module V1
  def_model 'forum_topics' do
    belongs_to :forum, class_name: 'ForumForum', inverse_of: nil
    include SeenByUserConcern

    scope :within_courses, ->(course_ids) do
      joins(:forum).where(forum: { course_id: Array(course_ids)})
    end

    def transform_topic_type
      # V1:
      # TOPIC_TYPES = [
      #   ['Normal', 0],
      #   ['Question', 1],
      #   ['Sticky', 2],
      #   ['Announcement', 3]
      # ]

      # V2:
      # enum topic_type: { normal: 0, question: 1, sticky: 2, announcement: 3 }

      case topic_type
      when 0
        :normal
      when 1
        :question
      when 2
        :sticky
      when 3
        :announcement
      end
    end

    def transform_creator_id(store)
      # author id references to UserCourse
      dst_course_user_id = store.get(V1::UserCourse.table_name,  author_id)
      user_id = ::CourseUser.find_by(id: dst_course_user_id).try(:user_id)
      user_id || ::User::DELETED_USER_ID
    end
  end

  def_model 'forum_topic_views' do
    belongs_to :topic, class_name: 'ForumTopic', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(topic: :forum).
        where(topic: { forum: { course_id: course_ids } })
    end
  end

  ::Course::Forum::Topic.class_eval do
    # Do not build initial post
    def generate_initial_post
    end

    def set_initial_post_title
    end

    def send_notification
    end

    def mark_as_read_for_creator
    end

    def mark_as_read_for_updater
    end
  end
end
