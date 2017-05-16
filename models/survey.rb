module V1
  def_model 'surveys'

  def_model 'survey_sections' do
    belongs_to :survey, class_name: 'Survey', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:survey).
        where(survey: { course_id: Array(course_ids) })
    end
  end

  def_model 'survey_questions' do
    belongs_to :section, class_name: 'SurveySection', foreign_key: :survey_section_id, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(section: :survey).
        where(section: { survey: { course_id: Array(course_ids) } })
    end
  end

  def_model 'survey_question_options' do
    belongs_to :question, class_name: 'SurveyQuestion', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(question: { section: :survey }).
        where(question: { section: { survey: { course_id: Array(course_ids) } } })
    end
  end
end
