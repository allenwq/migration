module CoursemologyV1::Source
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