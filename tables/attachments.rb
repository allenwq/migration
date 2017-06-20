class AttachmentsTable < BaseTable
  table_name 'file_uploads'
  scope { all }

  def migrate_batch(batch)
    batch.each do |old|
      ar = old.transform_attachment_reference(store, logger)

      store.set(model.table_name, old.id, ar.attachment.id) if ar
    end
  end
end

# Schema
#
# V2:
# create_table "attachments", force: :cascade do |t|
#   t.string   "name",        :limit=>255, :null=>false, :index=>{:name=>"index_attachments_on_name", :unique=>true}
#   t.text     "file_upload", :null=>false
#   t.datetime "created_at",  :null=>false
#   t.datetime "updated_at",  :null=>false
# end

# V1:
# create_table "file_uploads", :force => true do |t|
#   t.integer  "owner_id"
#   t.integer  "creator_id"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
#   t.string   "file_file_name"
#   t.string   "file_content_type"
#   t.integer  "file_file_size"
#   t.datetime "file_updated_at"
#   t.string   "owner_type"
#   t.string   "original_name"
#   t.string   "copy_url"
#   t.boolean  "is_public",         :default => true
# end
#
# add_index "file_uploads", ["creator_id"], :name => "index_file_uploads_on_creator_id"
# add_index "file_uploads", ["owner_id", "owner_type"], :name => "index_file_uploads_on_owner_id_and_owner_type"