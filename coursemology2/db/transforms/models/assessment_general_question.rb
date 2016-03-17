module CoursemologyV1::Source
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
end
