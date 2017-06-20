class AttachmentMigrator
  def initialize
  end

  def start
    AttachmentsTable.new(RedisStore.instance, Logger.new, [], 16).run
  end
end
