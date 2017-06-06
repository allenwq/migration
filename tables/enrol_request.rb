class EnrolRequestTable < BaseTable
  table_name 'enroll_requests'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::EnrolRequest.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :user_id do
          store.get(V1::User.table_name, old.user_id)
        end
        column :updated_at
        column :created_at

        # role_id either refers to 'student' or 'observer'.
        # Since 'observer' role feature is absent in v2 and broken in v1, ignore the column.

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_enrol_requests", force: :cascade do |t|
#   t.integer  "course_id",  :null=>false, :index=>{:name=>"fk__course_enrol_requests_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_enrol_requests_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "user_id",    :null=>false, :index=>{:name=>"fk__course_enrol_requests_user_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_enrol_requests_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end
# add_index "course_enrol_requests", ["course_id", "user_id"], :name=>"index_course_enrol_requests_on_course_id_and_user_id", :unique=>true

# V1
# create_table "enroll_requests", :force => true do |t|
#   t.integer  "user_id"
#   t.integer  "course_id"
#   t.integer  "role_id"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
#   t.time     "deleted_at"
# end
# add_index "enroll_requests", ["course_id"], :name => "index_enroll_requests_on_course_id"
# add_index "enroll_requests", ["role_id"], :name => "index_enroll_requests_on_role_id"
# add_index "enroll_requests", ["user_id"], :name => "index_enroll_requests_on_user_id"
