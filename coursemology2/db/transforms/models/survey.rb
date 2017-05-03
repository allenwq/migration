module V1::Source
  def_model 'surveys'

  def_model 'survey_sections' do
    belongs_to :survey, class_name: 'Survey', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:survey).
        where(survey: { course_id: Array(course_ids) })
    end
  end
end
