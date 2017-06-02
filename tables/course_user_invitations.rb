class CourseUserInvitationTable < BaseTable
  table_name 'mass_enrollment_emails'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::UserInvitation.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name
        column :email
        column :confirm_token => :invitation_key
        column :sent_at do
          if old.signed_up
            old.created_at
          else
            old.updated_at
          end
        end
        column :confirmed_at do
          if old.signed_up
            old.updated_at
          end
        end
        column :creator_id do
          User.system.id
        end
        column :updater_id do
          User.system.id
        end
        column :created_at
        column :updated_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_user_invitations", force: :cascade do |t|
#   t.integer  "course_id",      :null=>false, :index=>{:name=>"fk__course_user_invitations_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_user_invitations_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "name",           :limit=>255, :null=>false
#   t.string   "email",          :limit=>255, :null=>false, :index=>{:name=>"index_course_user_invitations_on_email", :case_sensitive=>false}
#   t.string   "invitation_key", :limit=>16, :null=>false, :index=>{:name=>"index_course_user_invitations_on_invitation_key", :unique=>true}
#   t.datetime "sent_at"
#   t.datetime "confirmed_at"
#   t.integer  "creator_id",     :null=>false, :index=>{:name=>"fk__course_user_invitations_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_user_invitations_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",     :null=>false, :index=>{:name=>"fk__course_user_invitations_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_user_invitations_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",     :null=>false
#   t.datetime "updated_at",     :null=>false
# end
# add_index "course_user_invitations", ["course_id", "email"], :name=>"index_course_user_invitations_on_course_id_and_email", :unique=>true

# V1
# create_table "mass_enrollment_emails", :force => true do |t|
#   t.integer  "course_id"
#   t.string   "name"
#   t.string   "email"
#   t.boolean  "signed_up",      :default => false
#   t.integer  "delayed_job_id"
#   t.datetime "created_at",                        :null => false
#   t.datetime "updated_at",                        :null => false
#   t.string   "confirm_token"
#   t.boolean  "pending_email",  :default => true
# end
