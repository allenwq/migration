def transform_materials(course_ids = [])
  transform_table :material_folders, to: ::Course::Material::Folder,
                  default_scope: proc { within_courses(course_ids).tsort } do
    primary_key :id
    column to: :parent_id do
      if source_record.parent_folder_id
        dst_id = CoursemologyV1::Source::MaterialFolder.transform(source_record.parent_folder_id)
        if !dst_id
          puts "Cannot find parent for #{source_record.class.name} #{source_record.id}"
        end
        dst_id
      end
    end

    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column to: :name do
      Pathname.normalize_filename(source_record.name)
    end
    column :description
    column :can_student_upload
    column to: :start_at do
      source_record.open_at || Time.zone.now
    end
    column :close_at, to: :end_at
    column :created_at
    column :updated_at

    save validate: false, if: proc {
      if !source_record.parent_folder_id
        # For root folder we just ignore and use course's default root folder.
        source_record.class.memoize_transform(source_record.id, course.root_folder)
        false
      elsif parent_id && valid?
        true
      else
        puts "Invalid #{source_record.class} #{source_record.primary_key_value}:"\
        " #{errors.full_messages.to_sentence}"
        false
      end
    }
  end

  transform_table :materials, to: ::Course::Material,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :folder_id do
      CoursemologyV1::Source::MaterialFolder.transform(source_record.folder_id)
    end
    column to: :name do
      source_record.transform_name
    end
    column to: :attachment_reference do
      attachment = source_record.file_upload.transform_attachment_reference
      self.name = nil if !attachment # Make it invalid so it won't be saved
      attachment
    end
    column :description
    # TODO: creator is overwrote
    column to: :creator_id do
      source_record.transform_creator_id
    end
    column :created_at
    column :updated_at

    skip_saving_unless_valid
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