module CoursemologyV1::Source
  def_model 'course_navbar_preferences'

  def_model 'courses' do
    has_many :course_navbar_preferences, inverse_of: nil

    def training_pref
      @training_pref ||= course_navbar_preferences.where(item: 'trainings').first ||
        CourseNavbarPreference.new(name: 'Trainings', pos: 2)
    end

    def mission_pref
      @mission_pref ||= course_navbar_preferences.where(item: 'missions').first ||
        CourseNavbarPreference.new(name: 'Missions', pos: 3)
    end

    def transform_logo
      if logo_url.present?
        Downloader.download_to_local(logo_url, self)
      end
    end
  end

  # Don't enroll creator in the course
  ::Course.class_eval { def set_defaults; end }
end
