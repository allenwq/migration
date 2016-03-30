module CoursemologyV1::Source
  def_model 'file_uploads' do
    scope :visible, ->() { where(is_public: true) }
    require 'open-uri'
    URL_PREFIX = 'http://coursemology.s3.amazonaws.com/file_uploads/files/'

    belongs_to :owner, polymorphic: true

    # Return the attachment reference or nil
    def transform_attachment_reference
      hash = $url_mapper.get_hash(url)
      reference = nil
      if hash && attachment = ::Attachment.find_by(name: hash)
        reference = ::AttachmentReference.new(
                      attachment: attachment,
                      name: sanitized_name
                    )
      elsif local_file = download_to_local
        attachment = ::Attachment.find_or_initialize_by(file: local_file)
        attachment.save!
        local_file.close unless local_file.closed?
        reference = ::AttachmentReference.new(attachment: attachment)
        reference.name = sanitized_name
        $url_mapper.set(url, reference.attachment.name, reference.url)
      end

      reference
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