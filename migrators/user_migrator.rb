class UserMigrator
  def initialize
  end

  def start
    UserTable.new(RedisStore.instance, Logger.new).run
  end
end
