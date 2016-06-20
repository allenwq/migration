module CoursemologyV1::Source
  def_model 'user_courses', 'announcements', 'levels'

  ::Course::Announcement.class_eval do
    # Ignore attachment callbacks.
    def update_attachment_references
    end
  end
end
