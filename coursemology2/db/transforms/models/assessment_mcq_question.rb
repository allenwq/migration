module V1::Source
  ::Course::Assessment::Question::MultipleResponse.class_eval do
    # skip validation
    raise 'Method removed validate_multiple_choice_has_solution' unless private_instance_methods(false).include?(:validate_multiple_choice_has_solution)
    def validate_multiple_choice_has_solution
    end
  end

  def_model 'assessment_mcq_questions' do
    has_one :assessment_question, as: :as_question, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(assessment_question: :assessments).
        where(
          {
            assessment_question: {
              assessments: {
                course_id: Array(course_ids)
              }
            }
          }
        )
      # where(id: 57365)
    end
  end

  def_model 'assessment_mcq_options' do
    belongs_to :question, class_name: AssessmentMcqQuestion.name, inverse_of: nil

    def self.within_courses(course_ids)
      joins({ question: { assessment_question: :assessments } }).
        where(
          {
            question: {
              assessment_question: {
                assessments: {
                  course_id: Array(course_ids)
                }
              }
            }
          }
        )
    end
  end
end