class UserMigrator
  def initialize
  end

  def start
    UserTable.new.run
  end
end