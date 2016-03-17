def transform_courses(ids = [])
  ids = Array(ids)

  transform_table :courses, to: ::Course, default_scope: proc { where(id: ids) } do
    primary_key :id
    column to: :creator_id do
      CoursemologyV1::Source::User.transform(source_record.creator_id)
    end
    column :title
    column :description
    # column :logo
    column :is_publish do
      # enum status: { closed: 0, published: 1, opened: 2 }
      if source_record.is_publish?
        self.status = :published
      elsif source_record.is_open?
        self.status = :opened
      else
        self.status = :closed
      end
    end

    column to: :assessment_categories do
      build_assessment_categories(source_record, self)
    end

    column to: :start_at do
      source_record.start_at || source_record.created_at
    end
    column to: :end_at do
      source_record.end_at || Time.now
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end
end

def build_assessment_categories(source, destination)
  if destination.assessment_categories.length == 0 || destination.assessment_categories.length > 1
    raise 'No category or more than 1 categories found'
  end

  default_category = destination.assessment_categories.first
  training_pref = source.training_pref

  default_category.assign_attributes(
    title: training_pref.name,
    weight: training_pref.pos,

    creator_id: CoursemologyV1::Source::User.transform(source.creator_id),
    updater_id: CoursemologyV1::Source::User.transform(source.creator_id),
    created_at: training_pref.created_at,
    updated_at: training_pref.updated_at
  )

  mission_pref = source.mission_pref
  mission_category = Course::Assessment::Category.new(
    title: mission_pref.name,
    weight: mission_pref.pos,

    creator_id: CoursemologyV1::Source::User.transform(source.creator_id),
    updater_id: CoursemologyV1::Source::User.transform(source.creator_id),
    created_at: mission_pref.created_at,
    updated_at: mission_pref.updated_at
  )
  [default_category, mission_category]
end

# V1:
# create_table "courses", :force => true do |t|
#   t.string   "title"
#   t.integer  "creator_id"
#   t.text     "description"
#   t.datetime "created_at",                             :null => false
#   t.datetime "updated_at",                             :null => false
#   t.string   "logo_url"
#   t.string   "banner_url"
#   t.time     "deleted_at"
#   t.boolean  "is_publish",          :default => false
#   t.boolean  "is_open",             :default => true
#   t.boolean  "is_active",           :default => true
#   t.datetime "start_at"
#   t.datetime "end_at"
#   t.boolean  "is_pending_deletion", :default => false
# end

# V2:
# create_table "courses", force: :cascade do |t|
#   t.integer  "instance_id",      null: false, index: {name: "fk__courses_instance_id"}, foreign_key: {references: "instances", name: "fk_courses_instance_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",            limit: 255,             null: false
#   t.text     "description"
#   t.text     "logo"
#   t.integer  "status",           default: 0, null: false
#   t.string   "registration_key", limit: 16, index: {name: "index_courses_on_registration_key", unique: true}
#   t.text     "settings"
#   t.datetime "start_at",         null: false
#   t.datetime "end_at",           null: false
#   t.integer  "creator_id",       null: false, index: {name: "fk__courses_creator_id"}, foreign_key: {references: "users", name: "fk_courses_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",       null: false, index: {name: "fk__courses_updater_id"}, foreign_key: {references: "users", name: "fk_courses_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",       null: false
#   t.datetime "updated_at",       null: false
# end
