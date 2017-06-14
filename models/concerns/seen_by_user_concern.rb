module SeenByUserConcern
  extend ActiveSupport::Concern

  included do
    has_many :seen_by_users, as: :obj, inverse_of: nil
  end

  def migrate_seen_by_users(store, logger, new)
    return if !new.id

    seen_by_users.includes(:user_course).find_each do |sbu|
      next unless sbu.user_course.present?

      reader_id = store.get(V1::User.table_name, sbu.user_course.user_id)
      readable_type = new.class.try(:readable_parent) || new.class.name
      # Timestamp must be >= new.updated_at, otherwise it's considered as unread
      rm = ReadMark.new(readable_id: new.id, readable_type: readable_type, reader_id: reader_id,  reader_type: 'User', timestamp: new.updated_at)
      begin
        rm.save!(validate: false)
        store.set(V1::SeenByUser.table_name, sbu.id, rm.id)
      rescue  ActiveRecord::RecordNotUnique => e
        logger.log "#{e.message}: #{sbu.class.name} #{sbu.id}"
      end
    end
  end
end