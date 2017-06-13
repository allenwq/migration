class AchievementTable < BaseTable
  table_name 'achievements'
  scope { |ids| where(course_id: ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Achievement.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :title
        column :description do
          ContentParser.parse_mc_tags(old.description)
        end
        if badge_file = old.transform_badge(logger)
          new.badge = badge_file
          badge_file.close unless badge_file.closed?
        end
        column :published
        column :weight do
          old.position || 0
        end
        column :creator_id do
          store.get(V1::User.table_name, old.creator_id)
        end
        new.updater_id = new.creator_id
        column :updated_at
        column :created_at

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id) if new.persisted?
      end
    end
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
