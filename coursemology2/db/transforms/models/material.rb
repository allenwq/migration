module CoursemologyV1::Source
  def_model 'material_folders' do
    belongs_to :parent, class_name: 'MaterialFolder', foreign_key: 'parent_folder_id', inverse_of: nil

    # Sort the records so that parent is always migrated before child.
    scope :tsort, ->() do
      result = all
      result.instance_eval do
        extend TSort

        alias tsort_each_node each

        def tsort_each_child(node, &block)
          [node.parent].each(&block) if node.parent
        end
      end

      result.tsort
    end
  end

  def_model 'materials' do
    belongs_to :folder, class_name: 'MaterialFolder', inverse_of: nil
    has_one :file_upload, as: :owner, inverse_of: nil

    scope :within_courses, ->(course_ids) {
      joins(:folder).where(folder: { course_id: course_ids }).includes(:file_upload)
    }

    def transform_name
      if file_upload
        Pathname.normalize_filename file_upload.original_name
      end
    end

    def transform_creator_id
      if file_upload
        file_upload.creator_id
      end
    end
  end

  def_model 'file_uploads' do
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
