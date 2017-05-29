# This is a memory store that caches all the writes in memory (in case we want to rollback)
class CachedWriteStore
  def initialize
    @store = {}
  end

  def get(namespace, key)
    new_key = combined_key(namespace, key)
    @store[new_key] || redis_store.get(namespace, key)
  end

  def set(namespace, key, value)
    return if value.nil?

    new_key = combined_key(namespace, key)
    @store[new_key] = value
  end

  def has_key?(namespace, key)
    new_key = combined_key(namespace, key)
    @store.has_key?(new_key) || redis_store.has_key?(namespace, key)
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

    @store = {}
  end

  private

  def combined_key(namespace, key)
    [namespace, key].to_yaml
  end
end
