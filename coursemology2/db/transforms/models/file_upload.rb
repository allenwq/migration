module CoursemologyV1::Source
  def_model 'file_uploads' do
    scope :visible, ->() { where(is_public: true) }
    require 'open-uri'
    URL_PREFIX = 'http://coursemology.s3.amazonaws.com/file_uploads/files/'
    LOCAL_DIR = '/tmp/file_uploads'

    belongs_to :owner, polymorphic: true

    def transform_attachment_reference
      hash = $url_mapper.get_hash(url)
      if hash && attachment = ::Attachment.find_by(name: hash)
        ::AttachmentReference.new(
          attachment: attachment,
          name: sanitized_name
        )
      else
        reference = ::AttachmentReference.new(file: download_to_local)
        reference.name = sanitized_name
        $url_mapper.set(url, reference.attachment.name, reference.url)
        reference
      end
    end

    def url
      URL_PREFIX + id_partition + '/original/' + file_file_name
    end

    def download_to_local
      FileUtils.mkdir_p(LOCAL_DIR) unless File.exist?(LOCAL_DIR)
      local_file_path = File.join(LOCAL_DIR, id.to_s + '_' + file_file_name)
      local_file = File.open(local_file_path, 'wb')
      open(url, 'rb') do |read_file|
        local_file.write(read_file.read)
      end
      local_file
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