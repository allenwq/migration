module CoursemologyV1::Source
  def_model 'assessment_coding_answers' do
    has_one :assessment_answer, as: :as_answer, inverse_of: nil
    delegate :submission_id, :question_id, :std_course_id, :content, :finalised, :correct,
             :assessment_answer_grading, :assessment_submission, to: :assessment_answer

    scope :with_eager_load, ->() do
      includes({ assessment_answer: [:std_course, :assessment_question, :assessment_answer_grading, :assessment_submission]})
    end

    scope :within_courses, ->(course_ids) do
      joins({ assessment_answer: :std_course }).
        where(
          {
            assessment_answer: {
              std_course: {
                course_id: Array(course_ids)
              }
            }
          }
        )
    end

    def transform_workflow_state
      # state :attempting
      # state :submitted
      # state :graded
      case assessment_submission.status
      when 'graded'
        :graded
      when 'submitted'
        :submitted
      else
        :attempting
      end
    end

    # Find the destination question_id through `AssessmentMcqQuestion` mapping
    def transform_question_id
      src_coding_id = assessment_answer.assessment_question.as_question_id
      dst_coding_id = CoursemologyV1::Source::AssessmentCodingQuestion.transform(src_coding_id)
      ::Course::Assessment::Question.
        find_by(actable_id: dst_coding_id,
                actable_type: ::Course::Assessment::Question::Programming.name).try(:id)
    end
  end
end

