module V1::Source
  def_model 'assessment_submissions' do
    belongs_to :assessment, inverse_of: nil
    belongs_to :std_course, class_name: 'UserCourse', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:assessment).where({assessment: { course_id: course_ids }})
    end

    def exp_awarded
      if status == 'graded'
        exps = self.class.connection.execute <<-SQL
            SELECT et.exp
              FROM exp_transactions et INNER JOIN assessment_gradings ag
                ON et.id = ag.exp_transaction_id
            WHERE ag.submission_id = "#{self.id}"
        SQL
        exps.first ? exps.first[0] : nil
      else
        nil
      end
    end
  end

  ::Course::Assessment::Submission.class_eval do
    # Skip auto grade
    def auto_grade_submission
    end

    # Skip notification
    def send_notification
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
