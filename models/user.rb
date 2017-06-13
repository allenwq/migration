module V1
  def_model 'users' do
    DEFAULT_PIC_URL = 'http://coursemology.s3.amazonaws.com/public/default_profile_pic.png'
    # All photos in this CDN are not accessible any more
    INVALID_URL = 'https://fbcdn-profile-a.akamaihd.net/'

    def transform_profile_photo(logger)
      if profile_photo_url.present? &&
        profile_photo_url != DEFAULT_PIC_URL &&
        !profile_photo_url.starts_with?(INVALID_URL)

        file_name = nil
        file_name = 'facebook.jpg' if facebook_url?(profile_photo_url)
        Downloader.download_to_local(profile_photo_url, self, logger, file_name)
      end
    end

    private

    def facebook_url?(url)
      !url.starts_with?('http://coursemology.s3.amazonaws.com'.freeze) &&
        !url.starts_with?('http://coursemology.org/'.freeze)
    end
  end

  ::User.class_eval do
    # Do not create read marks, for performance.
    def setup_new_reader
    end
  end

  ::InstanceUser.before_create do
    # enum role: { normal: 0, instructor: 1, administrator: 2, auto_grader: 3 }
    v1_email = user.email
    v1_user = User.find_by(email: v1_email)
    if v1_user && v1_user.system_role_id == 3
      self.role = :instructor
    end
  end
end
