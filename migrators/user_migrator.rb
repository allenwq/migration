class UserMigrator
  def initialize
  end

  def start
    UserTable.new(RedisStore.instance, [], 3).run
  end
end
