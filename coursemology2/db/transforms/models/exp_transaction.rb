module CoursemologyV1::Source
  def_model 'exp_transactions' do
    belongs_to :user_course, inverse_of: nil

    scope :within_courses, ->(course_ids) {
      joins(:user_course).where(user_course: { course_id: course_ids }).
        where(rewardable_id: nil) # Manually awarded exp
    }
  end

  ::Course::ExperiencePointsRecord.class_eval do
    def send_notification
    end
  end
end
