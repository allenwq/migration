module CoursemologyV1::Source
  def_model 'forum_posts' do
    belongs_to :topic, class_name: 'ForumTopic', inverse_of: nil
    belongs_to :parent, class_name: 'ForumPost', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(topic: :forum).
        where(topic: { forum: { course_id: Array(course_ids) } }).
        includes(:parent)
    end

    # Sort the records so that parent is always migrated before child.
    scope :tsort, ->() do
      result = all
      result.instance_eval do
        extend TSort

        alias tsort_each_node each

        def tsort_each_child(node, &block)
          [node.parent].each(&block) if node.parent
        end
      end

      result.tsort
    end

    def transform_creator_id
      # author id references to UserCourse
      dst_course_user_id = CoursemologyV1::Source::UserCourse.transform(author_id)
      user_id = ::CourseUser.find_by(id: dst_course_user_id).try(:user_id)
      puts "User not found ForumPost #{id}" unless user_id
      user_id
    end
  end
end
