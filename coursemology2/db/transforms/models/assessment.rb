module CoursemologyV1::Source
  def_model 'tabs', 'assessments'

  ::Course::Assessment.class_eval do
    # Disable draft validation
    def draft_status
    end
  end
end
