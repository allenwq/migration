module V1::Source
  def_model 'survey_submissions' do
    belongs_to :survey, class_name: 'Survey', inverse_of: nil
    belongs_to :user_course, class_name: 'UserCourse', inverse_of: nil
    has_many :mrq_answers, foreign_key: 'survey_submission_id', class_name: 'SurveyMrqAnswer', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:survey).
        where(survey: { course_id: Array(course_ids) })
    end

    def exp_transaction
      @exp ||= ExpTransaction.find_by(rewardable_type: 'Survey', rewardable_id: survey_id, user_course_id: user_course_id)
    end
  end

  ::Course::Survey::Response::TodoConcern.module_eval do
    raise 'Method removed' unless private_instance_methods(false).include?(:update_todo)
    def update_todo
    end

    raise 'Method removed' unless private_instance_methods(false).include?(:restart_todo)
    def restart_todo
    end
  end
end
