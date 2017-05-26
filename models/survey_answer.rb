module V1
  def_model 'survey_essay_answers' do
    belongs_to :user_course, class_name: 'UserCourse', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:user_course).
        where(user_course: { course_id: Array(course_ids) })
    end
  end

  def_model 'survey_mrq_answers' do
    belongs_to :user_course, class_name: 'UserCourse', inverse_of: nil
    belongs_to :survey_submission, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:user_course).
        where(user_course: { course_id: Array(course_ids) })
    end
  end
end
