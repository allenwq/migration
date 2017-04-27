module V1::Source
  def_model 'file_uploads' do
    scope :visible, ->() { where(is_public: true) }
    require 'open-uri'
    URL_PREFIX = 'http://coursemology.s3.amazonaws.com/file_uploads/files/'

    belongs_to :owner, polymorphic: true

    # Return the attachment reference or nil
    def transform_attachment_reference
      Downloader.url_to_attachment_reference(
        url,
        proc { Downloader.download_to_local(url, self, file_file_name) },
        name: sanitized_name,
        updated_at: updated_at - 8.hours,
        created_at: created_at - 8.hours,
        creator_id: User.transform(creator_id)
      )
    end

    def url
      if copy_url
        copy_url
      else
        URL_PREFIX + id_partition + '/original/' + file_file_name
      end
    end

    def download_to_local
      Downloader.download_to_local(url, self, file_file_name)
    end

    private

    def id_partition
      # Generate id format like 000/056/129
      str = id.to_s.rjust(9, '0')
      str[0..2] + '/' + str[3..5] + '/' + str[6..8]
    end

    def sanitized_name
      Pathname.normalize_filename(original_name)
    end
  end
end