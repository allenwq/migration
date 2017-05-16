module V1
  def_model 'assessment_general_answers' do
    has_one :assessment_answer, as: :as_answer, inverse_of: nil

    def method_missing(method, *args)
      return assessment_answer.send(method, *args) if assessment_answer.respond_to?(method)
      super
    end

    scope :with_eager_load, ->() do
      includes({ assessment_answer: [:std_course, :assessment_question, :assessment_answer_grading, assessment_submission: :assessment]})
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

    def transform_question_id
      src_trq_id = assessment_answer.assessment_question.as_question_id
      dst_trq_id = ::V1::AssessmentGeneralQuestion.transform(src_trq_id)
      ::Course::Assessment::Question.
        find_by(actable_id: dst_trq_id,
                actable_type: ::Course::Assessment::Question::TextResponse.name).try(:id)
    end
  end
end
