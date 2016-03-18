module CoursemologyV1::Source
  def_model 'assessment_answer_gradings'

  def_model 'assessment_answers' do
    belongs_to :assessment_question, foreign_key: 'question_id', inverse_of: nil
    belongs_to :assessment_submission, foreign_key: 'submission_id', inverse_of: nil
    belongs_to :std_course, class_name: 'UserCourse', inverse_of: nil
    has_one :assessment_answer_grading, foreign_key: 'answer_id', inverse_of: nil
  end

  ::Course::Assessment::Answer.class_eval do
    # Make sure that the validation still works if there is no question or submission.
    def validate_consistent_assessment
      return unless question && submission

      errors.add(:question, :consistent_assessment) if question.assessment_id != submission.assessment_id
    end

    def validate_assessment_state
      return unless submission
      errors.add(:submission, :attemptable_state) unless submission.attempting?
    end

    def validate_consistent_grade
      return unless question
      errors.add(:grade, :consistent_grade) if grade.present? && grade > question.maximum_grade
    end
  end
end
