module V1::Source
  def_model 'announcements' do
    time_shift :publish_at, :expiry_at
  end

  ::Course::Announcement.class_eval do
    # Ignore attachment callbacks.
    def update_attachment_references
    end

    # Do not send notification
    def send_notification
    end
  end
end
