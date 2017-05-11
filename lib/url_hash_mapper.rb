class UrlHashMapper
  def set_hash(v1_url, hash)
    store.set(table_key + '_hash', v1_url, hash)
  end

  def set_file_path(v1_url, path)
    store.set(table_key + '_path', v1_url, path)
  end

  def get_hash(v1_url)
    store.get(table_key + '_hash', v1_url)
  end

  # Return the local file path
  def get_file_path(v1_url)
    store.get(table_key + '_path', v1_url)
  end

  private

  def table_key
    's3_url_map'
  end

  def store
    @store ||= RedisStore.new
  end
end