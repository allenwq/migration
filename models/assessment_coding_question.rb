module V1
  ::Course::Assessment::Question::Programming.class_eval do
    # Disable package processing
    raise 'Method removed process_new_package' unless private_instance_methods(false).include?(:process_package)
    def process_package
    end
  end

  def_model 'assessment_coding_questions' do
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
    end

    def assessment
      @assessment ||=
        assessment_question.assessments.first
    end
  end
end
