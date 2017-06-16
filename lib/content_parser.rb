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

  # Parse v1 material urls to v2:
  # http://coursemology.org/courses/136/materials/files/4133 => http://coursemology.org/courses/315/materials/folders/xxx/files/xxx
  # http://coursemology.org/courses/315/materials/folders/8 => http://coursemology.org/courses/315/materials/folders/xxx
  MATERIAL_REG = /\/\/coursemology.org\/courses\/(\d+)\/materials\/(folders|files)\/(\d+)/
  def self.parse_material_urls(store, content)
    return content unless content.present?

    content.gsub!(MATERIAL_REG) do |s|
      folder_reg = /folders\/(\d+)/
      files_reg = /files\/(\d+)/

      old_folder_id = s.match(folder_reg)&.[](1)
      if old_folder_id && folder_id = store.get(V1::MaterialFolder.table_name, old_folder_id.to_i)
        s = s.sub(folder_reg, "folders/#{folder_id}")
      end

      old_file_id = s.match(files_reg)&.[](1)
      if old_file_id && file_id = store.get(V1::Material.table_name, old_file_id.to_i)
        folder_id = ::Course::Material.find_by(id:file_id)&.folder_id
        s = s.sub(files_reg, "folders/#{folder_id}/files/#{file_id}") if folder_id
      end

      s
    end

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
