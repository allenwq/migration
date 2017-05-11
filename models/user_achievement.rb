module V1::Source
  def_model 'user_achievements' do
    belongs_to :achievement, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      course_ids = Array(course_ids)
      joins(:achievement).where(achievement: { course_id: course_ids })
    end
  end

  ::Course::UserAchievement.class_eval do
    def send_notification
    end
  end
end