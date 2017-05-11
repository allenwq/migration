class YAMLStore
  STORE_PATH = Rails.root.join('tmp/saved_mappings')

  def initialize
    FileUtils.mkdir(STORE_PATH) unless File.exist?(STORE_PATH)
  end

  def get(key)
    path = File.join(STORE_PATH, "#{key}.yaml")
    if File.exist?(path)
      YAML.load(File.open(path))
    else
      {}
    end
  end

  def set(key, data)
    path = File.join(STORE_PATH, "#{key}.yaml")
    file = File.open(path, 'w')
    file.write data.to_yaml
    file.close
  end
end
