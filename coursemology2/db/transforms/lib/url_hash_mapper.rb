class UrlHashMapper
  def set_hash(v1_url, hash)
    store.set(table_key + '_hash', v1_url, hash)
  end

  def set_v2_url(v1_url, v2_url)
    store.set(table_key + '_url', v1_url, v2_url)
  end

  def set_file_path(v1_url, path)
    store.set(table_key + '_path', v1_url, path)
  end

  # Return the v2_url
  def get_url(v1_url)
    store.get(table_key + '_url', v1_url)
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