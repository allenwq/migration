module CoursemologyV1::Source
  def_model 'users' do
    DEFAULT_PIC_URL = 'http://coursemology.s3.amazonaws.com/public/default_profile_pic.png'.freeze

    def transform_profile_photo
      if profile_photo_url.present? && profile_photo_url != DEFAULT_PIC_URL
        file_name = nil
        file_name = 'facebook.jpg' if profile_photo_url.starts_with?('http://graph.facebook.com/')
        Downloader.download_to_local(profile_photo_url, self, file_name)
      end
    end
  end

  ::User.class_eval do
    # Do not create read marks, for performance.
    def setup_new_reader
    end
  end
end
