class MaterialFolderTable < BaseTable
  table_name 'material_folders'
  scope { |ids| within_courses(ids).tsort }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Material::Folder.new

      migrate(old, new) do
        column :parent_id do
          if old.parent_folder_id
            dst_id = store.get(V1::MaterialFolder.table_name, old.parent_folder_id)
            if dst_id.blank?
              logger.log "Cannot find parent for #{old.class.name} #{old.id}"
            end
            dst_id
          end
        end

        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name do
          Pathname.normalize_filename(old.name)
        end
        column :description
        column :can_student_upload
        column :start_at do
          old.open_at || old.created_at
        end
        column :close_at => :end_at
        column :created_at
        column :updated_at

        if !old.parent_folder_id
          # For root folder we just ignore and use course's default root folder.
          store.set(model.table_name, old.id, new.course.root_folder.id)
        elsif new.parent_id && new.valid?
          new.save(validate: false)
          store.set(model.table_name, old.id, new.id)
        elsif new.parent
          # Merge duplicate folders
          other = new.parent.children.find_by(name: new.name)
          store.set(model.table_name, old.id, other.id) if other
        else
          logger.log "Invalid #{old.class} #{old.primary_key_value}: #{errors.full_messages.to_sentence}"
        end
      end
    end
  end
end

class MaterialTable < BaseTable
  table_name 'materials'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Material.new

      migrate(old, new) do
        column :folder_id do
          store.get(V1::MaterialFolder.table_name, old.folder_id)
        end
        column :name do
          old.transform_name
        end
        column :attachment_reference do
          old.file_upload.transform_attachment_reference(store, logger)
        end
        column :description
        column :creator_id do
          old.transform_creator_id(store)
        end
        column :updater_id do
          new.creator_id
        end
        column :created_at
        column :updated_at

        if new.attachment_reference
          skip_saving_unless_valid
          store.set(model.table_name, old.id, new.id)
        end
      end
    end
  end
end

# Schema
#
# V2:
#
# create_table "course_material_folders", force: :cascade do |t|
#   t.integer  "parent_id",          index: {name: "fk__course_material_folders_parent_id"}, foreign_key: {references: "course_material_folders", name: "fk_course_material_folders_parent_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "course_id",          null: false, index: {name: "fk__course_material_folders_course_id"}, foreign_key: {references: "courses", name: "fk_course_material_folders_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "owner_id",           index: {name: "index_course_material_folders_on_owner_id_and_owner_type", with: ["owner_type"], unique: true}
#   t.string   "owner_type",         limit: 255, index: {name: "fk__course_material_folders_owner_id", with: ["owner_id"]}
#   t.string   "name",               limit: 255,                 null: false
#   t.text     "description"
#   t.boolean  "can_student_upload", default: false, null: false
#   t.datetime "start_at",           null: false
#   t.datetime "end_at"
#   t.integer  "creator_id",         null: false, index: {name: "fk__course_material_folders_creator_id"}, foreign_key: {references: "users", name: "fk_course_material_folders_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",         null: false, index: {name: "fk__course_material_folders_updater_id"}, foreign_key: {references: "users", name: "fk_course_material_folders_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",         null: false
#   t.datetime "updated_at",         null: false
# end
#
# create_table "course_materials", force: :cascade do |t|
#   t.integer  "folder_id",   null: false, index: {name: "fk__course_materials_folder_id"}, foreign_key: {references: "course_material_folders", name: "fk_course_materials_folder_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "name",        limit: 255, null: false
#   t.text     "description"
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_materials_creator_id"}, foreign_key: {references: "users", name: "fk_course_materials_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_materials_updater_id"}, foreign_key: {references: "users", name: "fk_course_materials_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end

# V1:
#
# create_table "material_folders", :force => true do |t|
#   t.integer  "parent_folder_id"
#   t.integer  "course_id"
#   t.string   "name"
#   t.text     "description"
#   t.datetime "open_at"
#   t.datetime "close_at"
#   t.boolean  "can_student_upload", :default => false
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end
#
# create_table "materials", :force => true do |t|
#   t.integer  "folder_id"
#   t.text     "description"
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end
#
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
