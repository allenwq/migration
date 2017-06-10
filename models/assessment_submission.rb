module V1
  def_model 'assessment_submissions' do
    belongs_to :assessment, inverse_of: nil
    belongs_to :std_course, class_name: 'UserCourse', inverse_of: nil
    has_many :gradings, class_name: 'AssessmentGrading', foreign_key: 'submission_id', inverse_of: nil
    has_many :file_uploads, as: :owner, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:assessment).where({assessment: { course_id: course_ids }}).includes(gradings: :exp_transaction)
    end

    def exp_awarded
      if status == 'graded' && gradings.first
        gradings.first&.exp_transaction&.exp
      else
        nil
      end
    end

    def published_at
      if status == 'graded' && gradings.first
        gradings.first.created_at
      else
        nil
      end
    end

    def publisher_id
      if status == 'graded' && gradings.first
        gradings.first.grader_id
      else
        nil
      end
    end
  end

  def_model 'assessment_gradings' do
    belongs_to :submission, class_name: 'AssessmentSubmission', inverse_of: nil
    belongs_to :exp_transaction, class_name: 'ExpTransaction', inverse_of: nil
  end

  ::Course::Assessment::Submission.class_eval do
    # Skip update todo
    def update_todo
    end

    # Skip draft exp assign
    def assign_experience_points
    end

    # Skip auto grade
    def auto_grade_submission
    end

    # Skip notification
    def send_attempt_notification
    end

    # Skip notification
    def send_submit_notification
    end

    # Overwrite the validation for better performance in migration
    def validate_consistent_user
      return if course_user && course_user.user_id == creator_id
      errors.add(:experience_points_record, :inconsistent_user)
    end

    def validate_awarded_attributes
      return if awarded_at && awarder_id
      errors.add(:experience_points_record, :absent_award_attributes)
    end

    def validate_unique_submission
      existing = ::Course::Assessment::Submission.
        find_by(assessment_id: assessment_id || assessment&.id, creator_id: creator_id || creator&.id)

      return unless existing
      errors.clear
      errors[:base] << I18n.t('activerecord.errors.models.course/assessment/'\
                            'submission.submission_already_exists')
    end
  end

  # Skip conditional callbacks.
  ::Course::Condition::Assessment.class_eval do
    def self.on_dependent_status_change(*args)
    end
  end

  ::Course::Condition::Level.class_eval do
    def self.on_dependent_status_change(*args)
    end
  end

  ::Course::Condition::Achievement.class_eval do
    def self.on_dependent_status_change(*args)
    end
  end
end
