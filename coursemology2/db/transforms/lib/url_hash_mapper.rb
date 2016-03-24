require_relative 'yaml_store'

class UrlHashMapper
  # { v1_url: [ hash, v2_url ] }
  def initialize
    @data = store.get(store_key)
    @count = 0
  end

  def set(v1_url, hash, v2_url = nil)
    @data[v1_url] = [hash, v2_url]
    @count += 1

    # Persist to disk for every 100 records
    if @count > 100
      persist
      @count = 0
    end

    [hash, v2_url]
  end

  def get_url(v1_url)
    if value = @data[v1_url]
      value[1]
    end
  end

  def get_hash(v1_url)
    if value = @data[v1_url]
      value[0]
    end
  end

  def persist
    store.set(store_key, @data)
  end

  private

  def store_key
    's3_url_hash'
  end

  def store
    @store ||= YAMLStore.new
  end
end