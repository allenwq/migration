module CoursemologyV1::Source
  def_model 'course_navbar_preferences'

  def_model 'courses' do
    has_many :course_navbar_preferences, inverse_of: nil

    def training_pref
      @training_pref ||= course_navbar_preferences.where(item: 'trainings').first
    end

    def mission_pref
      @mission_pref ||= course_navbar_preferences.where(item: 'missions').first
    end
  end

  # Don't enroll creator in the course
  ::Course.class_eval { def set_defaults; end }
end
