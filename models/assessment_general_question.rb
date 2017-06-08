module V1
  def_model 'assessment_general_questions' do
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

  def_model 'assessment_auto_grading_exact_options' do
    belongs_to :general_question, class_name: 'AssessmentGeneralQuestion', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(general_question: { assessment_question: :assessments }).
        where(
          {
            general_question: {
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

  def_model 'assessment_auto_grading_keyword_options' do
    belongs_to :general_question, class_name: 'AssessmentGeneralQuestion', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(general_question: { assessment_question: :assessments }).
        where(
          {
            general_question: {
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
