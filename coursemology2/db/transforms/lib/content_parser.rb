class ContentParser
  def self.parse_mc_tags(content)
    return content unless content.present?

    content.gsub!('[mc]', '<pre class="codehilite codehilite-python"><code>')
    content.gsub!('[/mc]', '</code></pre>')

    content.gsub!('[c]', '<pre class="codehilite codehilite-python"><code>')
    content.gsub!('[/c]', '</code></pre>')
    content
  end
end
