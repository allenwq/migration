class UserMigrator
  def initialize
  end

  def start
    UserTable.new(RedisStore.instance).run
  end
end