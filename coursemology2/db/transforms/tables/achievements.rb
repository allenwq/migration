def transform_achievements(course_ids = [])
  transform_table :achievements,
                  to: ::Course::Achievement,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column :title
    column to: :description do
      ContentParser.parse_mc_tags(source_record.description)
    end
    column :icon_url do
      badge_file = source_record.transform_badge
      if badge_file
        self.badge = badge_file
        badge_file.close unless badge_file.closed?
      end
    end
    column :published, to: :draft do |published|
      !published
    end
    column :position, to: :weight do |position|
      position || 0
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
# create_table "course_achievements", force: :cascade do |t|
#   t.integer  "course_id",   null: false, index: {name: "fk__course_achievements_course_id"}, foreign_key: {references: "courses", name: "fk_course_achievements_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",       limit: 255, null: false
#   t.text     "description"
#   t.text     "badge"
#   t.integer  "weight",      null: false
#   t.boolean  "draft",       null: false
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_achievements_creator_id"}, foreign_key: {references: "users", name: "fk_course_achievements_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_achievements_updater_id"}, foreign_key: {references: "users", name: "fk_course_achievements_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end

# V1
# create_table "achievements", :force => true do |t|
#   t.string   "icon_url"
#   t.string   "title"
#   t.text     "description"
#   t.integer  "creator_id"
#   t.integer  "course_id"
#   t.datetime "created_at",                                      :null => false
#   t.datetime "updated_at",                                      :null => false
#   t.time     "deleted_at"
#   t.boolean  "auto_assign"
#   t.text     "requirement_text"
#   t.boolean  "published",                     :default => true
#   t.integer  "facebook_obj_id",  :limit => 8
#   t.integer  "position"
# end
