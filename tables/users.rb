class UserTable < BaseTable
  table_name 'users'
  scope { all }

  def migrate_batch(batch)
    batch.each do |old|
      new_id = store.get(V1::User.table_name, old.id)
      if new_id.present?
        fix_timestamps(old, new_id)
        fix_permissions(old, new_id)
        next # Don't migrate if user is memoized.
      elsif v2_email = User::Email.find_by(email: old.email)
        # If there's already an email, just memoize and return
        store.set(model.table_name, old.id, v2_email.user_id)
        next
      end

      logger.log "migrate #{old.id}"
      new = ::User.new

      migrate(old, new) do
        column :name
        column :email

        if old.confirmed_at.present?
          new.primary_email_record.confirmed_at = old.confirmed_at
        else
          new.skip_confirmation_notification!
        end

        photo_file = old.transform_profile_photo(logger)
        if photo_file
          new.profile_photo = photo_file
          photo_file.close unless photo_file.closed?
        end

        column :encrypted_password
        column :sign_in_count
        column :current_sign_in_at
        column :last_sign_in_at
        column :current_sign_in_ip
        column :last_sign_in_ip
        column :role do
          # Roles
          # V1: { superuser: 1, normal: 2, lecturer: 3, ta: 4, student: 5, shared: 6 }
          # V2: { normal: 0, administrator: 1, auto_grader: 2 } (For users)
          case old.system_role_id
          when 1
            1
          else
            0
          end
        end
        column :time_zone do
          old.time_zone || 'Singapore'
        end
        column :updated_at
        column :created_at

        if old.uid.present? && old.provider == 'facebook'
          auth = { provider: 'facebook', uid: old.uid }
          # The check is for that some users are migrated to v2 and changed their email
          if ::User::Identity.where(auth).count == 0
            new.link_with_omniauth(auth)
          end
        end

        new.save!(validate: false)
        store.set(model.table_name, old.id, new.id)

        fix_permissions(old, new.id)
      end
    end
  end

  def fix_timestamps(old, new_id)
    # Map v1 user timestamps to v2
    new = ::User.find_by(id: new_id)

    unless new.present?
      logger.log "Cannot find user #{new_id}, old: #{old.id}"
      return
    end

    if (new.updated_at - new.created_at).abs < 1.minute
      new.update_column(:updated_at, old.updated_at)
    end
    new.update_column(:created_at, old.created_at)
  end

  def fix_permissions(old, new_id)
    return unless ::User.find_by(id: new_id).present?
    # If the old user is a lecturer on v1, it should be a lecturer on v2 default instance
    return unless old.system_role_id == 3

    ius = ::InstanceUser.unscoped.where(id: new_id).to_a
    return if ius.any? { |iu| iu.role == 'instructor' }

    if ius.empty?
      ::InstanceUser.create(user_id: new_id, role: :instructor)
    else
      ius.first.update_column(:role, 1)
    end
  end
end

# create_table "users", :force => true do |t|
#   t.string   "name"
#   t.string   "profile_photo_url"
#   t.string   "display_name"
#   t.datetime "created_at",                                                       :null => false
#   t.datetime "updated_at",                                                       :null => false
#   t.string   "email",                                         :default => "",    :null => false
#   t.string   "encrypted_password",                            :default => "",    :null => false
#   t.string   "reset_password_token"
#   t.datetime "reset_password_sent_at"
#   t.datetime "remember_created_at"
#   t.integer  "sign_in_count",                                 :default => 0
#   t.datetime "current_sign_in_at"
#   t.datetime "last_sign_in_at"
#   t.string   "current_sign_in_ip"
#   t.string   "last_sign_in_ip"
#   t.integer  "system_role_id"
#  [1, "superuser"],
#  [2, "normal"],
#  [3, "lecturer"],
#  [4, "ta"],
#  [5, "student"],
#  [6, "shared"]
#   t.time     "deleted_at"
#   t.string   "provider"
#   t.string   "uid"
#   t.string   "unconfirmed_email"
#   t.string   "confirmation_token"
#   t.datetime "confirmed_at"
#   t.datetime "confirmation_sent_at"
#   t.boolean  "is_logged_in",                                  :default => true
#   t.boolean  "is_pending_deletion",                           :default => false
#   t.boolean  "use_uploaded_picture",                          :default => false
#   t.integer  "fb_publish_actions_request_count", :limit => 1, :default => 0,     :null => false
#   t.string   "time_zone"
# end

# V2:
# create_table "users", force: :cascade do |t|
#   t.string   "name",                   limit: 255,              null: false
#   t.integer  "role",                   default: 0,  null: false
#   t.text     "profile_photo"
#   t.string   "encrypted_password",     limit: 255, default: "", null: false
#   t.string   "authentication_token",   limit: 255, index: {name: "index_users_on_authentication_token", unique: true}
#   t.string   "reset_password_token",   limit: 255, index: {name: "index_users_on_reset_password_token", unique: true}
#   t.datetime "reset_password_sent_at"
#   t.datetime "remember_created_at"
#   t.integer  "sign_in_count",          default: 0,  null: false
#   t.datetime "current_sign_in_at"
#   t.datetime "last_sign_in_at"
#   t.inet     "current_sign_in_ip"
#   t.inet     "last_sign_in_ip"
#   t.datetime "created_at",             null: false
#   t.datetime "updated_at",             null: false
# end

# create_table "user_emails", force: :cascade do |t|
#   t.boolean  "primary",              :default=>false, :null=>false
#   t.integer  "user_id",              :index=>{:name=>"index_user_emails_on_user_id_and_primary", :with=>["primary"], :unique=>true, :where=>"(\"primary\" <> false)"}, :foreign_key=>{:references=>"users", :name=>"fk_user_emails_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "email",                :limit=>255, :null=>false, :index=>{:name=>"index_user_emails_on_email", :unique=>true, :case_sensitive=>false}
#   t.string   "confirmation_token",   :limit=>255, :index=>{:name=>"index_user_emails_on_confirmation_token", :unique=>true}
#   t.datetime "confirmed_at"
#   t.datetime "confirmation_sent_at"
#   t.string   "unconfirmed_email",    :limit=>255
# end
