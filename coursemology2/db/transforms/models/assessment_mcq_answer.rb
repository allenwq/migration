module CoursemologyV1::Source
  def_model 'assessment_mcq_answers' do
    has_one :assessment_answer, as: :as_answer, inverse_of: nil
    delegate :submission_id, :question_id, :std_course_id, :content, :finalised, :correct,
             :assessment_answer_grading, :assessment_submission, to: :assessment_answer

    scope :with_eager_load, ->() do
      includes({ assessment_answer: [:assessment_question, :assessment_answer_grading]})
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

    # Find the destination question_id through `AssessmentMcqQuestion` mapping
    def transform_question_id
      src_mcq_id = assessment_answer.assessment_question.as_question_id
      dst_mcq_id = AssessmentMcqQuestion.transform(src_mcq_id)
      ::Course::Assessment::Question.
        find_by(actable_id: dst_mcq_id,
                actable_type: ::Course::Assessment::Question::MultipleResponse.name).try(:id)
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
  end

  def_model 'assessment_answer_options' do
    belongs_to :assessment_mcq_answer, foreign_key: 'answer_id', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins({ assessment_mcq_answer: { assessment_answer: :std_course } }).
        where(
          {
            assessment_mcq_answer: {
              assessment_answer: {
                std_course: {
                  course_id: Array(course_ids)
                }
              }
            }
          }
        )
    end
  end
end
