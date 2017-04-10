class Downloader
  LOCAL_DIR = '/tmp/file_downloads'

  class << self
    # Download the url to local and return an open file. nil will be returned if failed.
    def download_to_local(url, object, file_name = nil)
      dir = download_dir(object)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)

      file_name ||= name_from_url(url)
      local_file_path = File.join(dir, file_name)
      return File.open(local_file_path) if File.exist?(local_file_path)

      local_file = File.open(local_file_path, 'wb')
      tries = 10
      begin
        open(url, 'rb') do |read_file|
          local_file.write(read_file.read)
        end
      rescue StandardError => e
        tries -= 1
        if tries > 0
          retry
        else
          puts "Download #{object.class} #{object.primary_key_value} failed, error: #{e.inspect}"
          local_file.close
          File.delete(local_file_path)
          local_file = nil
        end
      end

      local_file
    end

    # @param [Proc] download_proc, the proc which downloads the file, if url is not found in
    #   cache, file will be downloaded.
    def url_to_attachment_reference(url, download_proc, name = nil)
      name ||= name_from_url(url)
      hash = $url_mapper.get_hash(url)
      reference = nil
      if hash && attachment = ::Attachment.find_by(name: hash)
        reference = ::AttachmentReference.new(
          attachment: attachment,
          name: name
        )
      elsif local_file = download_proc.call
        attachment = ::Attachment.find_or_initialize_by(file: local_file)
        attachment.save! unless attachment.persisted?
        local_file.close unless local_file.closed?
        reference = ::AttachmentReference.new(attachment: attachment)
        reference.name = name
        $url_mapper.set(url, reference.attachment.name, reference.url)
      end

      reference
    end

    private

    def download_dir(object)
      File.join(LOCAL_DIR, object.class.table_name, object.primary_key_value.to_s)
    end

    # Url is must be a S3 url
    def name_from_url(url)
      return '' unless url.present?
      start = url.index('original/') + 'original/'.length
      url[start..-12]
    end
  end
end