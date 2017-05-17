# This is a memory store that caches all the writes in memory (in case we want to rollback)
class CachedWriteStore
  def initialize
    @store = {}
  end

  def get(namespace, key)
    key = combined_key(namespace, key)
    @store[key] || redis_store.get(namespace, key)
  end

  def set(namespace, key, value)
    key = combined_key(namespace, key)
    @store[key] = value
  end

  def has_key?(namespace, key)
    key = combined_key(namespace, key)
    @store.has_key?(key) || redis_store.has_key?(namespace, key)
  end

  def reset(namespace)
    raise 'Not implemented'
  end

  def redis_store
    RedisStore.instance
  end

  def persist_to_redis
    @store.each_pair do |key, value|
      namespace, actual_key = YAML.load(key)
      redis_store.set(namespace, actual_key, value)
    end
  end

  private

  def combined_key(namespace, key)
    [namespace, key].to_yaml
  end
end
