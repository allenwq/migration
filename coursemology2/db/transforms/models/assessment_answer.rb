module CoursemologyV1::Source
  def_model 'assessment_answer_gradings'

  def_model 'assessment_answers' do
    belongs_to :assessment_question, foreign_key: 'question_id', inverse_of: nil
    belongs_to :assessment_submission, foreign_key: 'submission_id', inverse_of: nil
    belongs_to :std_course, class_name: 'UserCourse', inverse_of: nil
    belongs_to :as_answer, polymorphic: true, inverse_of: nil
    has_one :assessment_answer_grading, foreign_key: 'answer_id', inverse_of: nil

    def self.transform(src_id_or_object, specific = false)
      return unless src_id_or_object

      if src_id_or_object.is_a?(Integer)
        src_answer = find(src_id_or_object)
      else
        return if src_id_or_object.as_answer_type.nil?
        src_answer = src_id_or_object
      end
      src_specific_answer = src_answer.as_answer
      dst_specific_answer_id = src_specific_answer.class.transform(src_specific_answer.id)

      type = nil

      case src_specific_answer.class.name.demodulize
      when AssessmentMcqAnswer.name.demodulize
        type = ::Course::Assessment::Answer::MultipleResponse.name
      when AssessmentGeneralAnswer.name.demodulize
        type = ::Course::Assessment::Answer::TextResponse.name
      when AssessmentCodingAnswer.name.demodulize
        type = ::Course::Assessment::Answer::Programming.name
      end

      if specific
        dst_specific_answer_id
      else
        ::Course::Assessment::Answer.find_by(actable_type: type, actable_id:
          dst_specific_answer_id).try(:id)
      end
    end
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
