def transform_announcements(course_ids = [])
  transform_table :announcements,
                  to: ::Course::Announcement,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column :title, to: :title do |title|
      # some of the announcements don't have titles,
      # example: http://coursemology.org/courses/193/announcements
      title.present? ? title : '( No Title )'
    end
    column :description, to: :content do |description|
      description = ContentParser.parse_mc_tags(description)
      description, references = ContentParser.parse_images(source_record, description)
      self.attachment_references = references if references.any?
      description
    end
    column :publish_at, to: :start_at
    column :expiry_at, to: :end_at do |expiry_at|
      expiry_at || Time.now
    end
    column to: :creator_id do
      result = CoursemologyV1::Source::User.transform(source_record.creator_id)
      self.updater_id = result
      result
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_announcements", force: :cascade do |t|
#   t.integer  "course_id",  null: false, index: {name: "fk__course_announcements_course_id"}, foreign_key: {references: "courses", name: "fk_course_announcements_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",      limit: 255,                 null: false
#   t.text     "content"
#   t.boolean  "sticky",     default: false, null: false
#   t.datetime "start_at",   null: false
#   t.datetime "end_at",     null: false
#   t.integer  "creator_id", null: false, index: {name: "fk__course_announcements_creator_id"}, foreign_key: {references: "users", name: "fk_course_announcements_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id", null: false, index: {name: "fk__course_announcements_updater_id"}, foreign_key: {references: "users", name: "fk_course_announcements_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
# end

# V1
# create_table "announcements", :force => true do |t|
#   t.integer  "creator_id"
#   t.integer  "course_id"
#   t.datetime "publish_at"
#   t.integer  "important"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
#   t.string   "title"
#   t.text     "description"
#   t.time     "deleted_at"
#   t.datetime "expiry_at"
# end