class UrlHashMapper
  # { v1_url: [ hash, v2_url ] }
  def set(v1_url, hash, v2_url = nil)
    value = [hash, v2_url]
    store.set(table_key, v1_url, value)
  end

  def get_url(v1_url)
    if value = store.get(table_key, v1_url)
      value[1]
    end
  end

  def get_hash(v1_url)
    if value = store.get(table_key, v1_url)
      value[0]
    end
  end

  private

  def table_key
    's3_url_hash'
  end

  def store
    @store ||= RedisStore.new
  end
end