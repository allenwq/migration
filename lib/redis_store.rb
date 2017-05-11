class RedisStore
  def initialize
    @store = Redis.new
  end

  def get(table_name, key)
    key = combined_key(table_name, key)
    @store.get(key)
  end

  def set(table_name, key, value)
    key = combined_key(table_name, key)
    @store.set(key, value)
  end

  def has_key?(table_name, key)
    key = combined_key(table_name, key)
    @store.exists(key)
  end

  # Clear all the data of specific table from Redis.
  # This should be called before migrating the table.
  def reset_table(table_name)
    @store.keys([table_name].to_yaml + '*').each do |key|
      @store.del(key)
    end
  end

  private

  def combined_key(table_name, key)
    [table_name, key].to_yaml
  end
end
