# This is a wrapper of Redis that provides a namespace
class RedisStore
  def self.instance
    @instance ||= self.new
  end

  def initialize
    @store = Redis.new
  end

  def get(namespace, key)
    key = combined_key(namespace, key)
    @store.get(key)
  end

  def set(namespace, key, value)
    key = combined_key(namespace, key)
    @store.set(key, value)
  end

  def has_key?(namespace, key)
    key = combined_key(namespace, key)
    @store.exists(key)
  end

  # Clear all the data of specific namespace from Redis.
  def reset(namespace)
    @store.keys([namespace].to_yaml + '*').each do |key|
      @store.del(key)
    end
  end

  private

  def combined_key(namespace, key)
    [namespace, key].to_yaml
  end
end
