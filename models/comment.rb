module V1
  def_model 'comments' do
    belongs_to :assessment_answer, foreign_key: 'commentable_id', inverse_of: nil
    belongs_to :user_course, inverse_of: nil
    default_scope do
      where(deleted_at: nil).where(commentable_type: 'Assessment::Answer')
    end

    scope :within_courses, ->(course_ids) do
      joins(assessment_answer: :std_course).
        where(assessment_answer: { std_course: { course_id: course_ids } }).
        # There is a issue when includes :user_course, the user_course loaded is actually
        # :std_course
        includes(:assessment_answer)
    end

    def transform_topic_id
      ::Course::Discussion::Topic.find_by(actable_id: CommentTopic.transform(comment_topic_id),
                                          actable_type: 'Course::Assessment::SubmissionQuestion').try(:id)
    end

    def transform_creator_id
      user_id = User.transform(user_course.user_id)
      user_id || ::User::DELETED_USER_ID
    end
  end

  def_model 'annotations' do
    belongs_to :assessment_answer, foreign_key: 'annotable_id', inverse_of: nil
    belongs_to :user_course, inverse_of: nil

    default_scope do
      where(deleted_at: nil).where(annotable_type: 'Assessment::Answer')
    end

    scope :within_courses, ->(course_ids) do
      joins(assessment_answer: :std_course).
        where(assessment_answer: { std_course: { course_id: course_ids } }).
        # There is a issue when includes :user_course, the user_course loaded is actually
        # :std_course
        includes(:assessment_answer)
    end

    def transform_file
      dst_specific_answer_id = AssessmentAnswer.transform(assessment_answer, true)
      if dst_specific_answer_id
        ::Course::Assessment::Answer::ProgrammingFile.where(answer_id: dst_specific_answer_id).first
      end
    end

    def transform_creator_id
      user_id = User.transform(user_course.user_id)
      user_id || ::User::DELETED_USER_ID
    end
  end

  # Do not touch the topic when create the post
  ::Course::Discussion::Post._reflect_on_association(:topic).options.delete(:touch)
  ::Course::Discussion::Post._save_callbacks.select {|cb| cb.kind  == :after && cb.name == :save }.each do |cb|
    Course::Discussion::Post._save_callbacks.delete(cb)
  end
end
