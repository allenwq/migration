class ContentParser
  def self.parse_mc_tags(content)
    return content unless content.present?

    content.gsub!('[mc]', '<pre lang="python"><code>')
    content.gsub!('[/mc]', '</code></pre>')

    content.gsub!('[c]', '<span lang="python"><code>')
    content.gsub!('[/c]', '</code></span>')

    content.gsub!("\u0000", '')
    content
  end

  # Parse the image in the record, and translate them into attachment_references
  # Url format:
  # <img alt="" src="http://coursemology.s3.amazonaws.com/file_uploads/files/xxx">
  def self.parse_images(record, content, logger)
    html = Nokogiri::HTML(content)
    h = {}
    references = []
    html.xpath('//img').each do |image|
      src = image['src']
      if src.present? && src.starts_with?('http://coursemology.s3.amazonaws.com/')
        download_proc = proc { Downloader.download_to_local(src, record, logger) }
        attachment_reference = Downloader.url_to_attachment_reference(
          src,
          download_proc
        )
        if attachment_reference
          attachment_reference.save!
          h[src] = "/attachments/#{attachment_reference.id}"
          references << attachment_reference
        end
      end
    end

    h.each do |key, value|
      content.gsub!(key, value)
    end

    return content, references
  end
end
