class SurveyTable < BaseTable
  table_name 'surveys'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Survey.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :title do
          old.title.present? ? old.title : 'Untitled'
        end
        column :description do
          description = ContentParser.parse_mc_tags(old.description)
          description, references = ContentParser.parse_images(old, description, logger)
          new.attachment_references = references if references.any?
          description
        end
        column :base_exp do
          old.exp || 0
        end
        column :time_bonus_exp do
          0
        end
        column :open_at => :start_at
        column :expire_at => :end_at
        column :publish => :published

        column :anonymous
        column :allow_modify => :allow_response_after_end

        column :creator_id do
          result = store.get(V1::User.table_name, old.creator_id)
          new.updater_id = result
          result
        end
        column :updated_at do
          new.lesson_plan_item.updated_at = old.updated_at
          old.updated_at
        end
        column :created_at do
          new.lesson_plan_item.created_at = old.created_at
          old.created_at
        end

        if new.end_at && new.start_at && new.end_at < new.start_at
          # Drop end_at if it's before start at
          new.end_at = nil

          logger.log "End at before start at #{old.class} #{old.id}, set to nil"
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_lesson_plan_items", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",           :limit=>255, :index=>{:name=>"index_course_lesson_plan_items_on_actable_type_and_actable_id", :with=>["actable_id"], :unique=>true}
#   t.integer  "course_id",              :null=>false, :index=>{:name=>"fk__course_lesson_plan_items_course_id"}, :foreign_key=>{:references=>"courses", :name=>"fk_course_lesson_plan_items_course_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "title",                  :limit=>255, :null=>false
#   t.text     "description"
#   t.boolean  "published",              :default=>false, :null=>false
#   t.integer  "base_exp",               :null=>false
#   t.integer  "time_bonus_exp",         :null=>false
#   t.datetime "start_at",               :null=>false
#   t.datetime "bonus_end_at"
#   t.datetime "end_at"
#   t.float    "opening_reminder_token"
#   t.float    "closing_reminder_token"
#   t.integer  "creator_id",             :null=>false, :index=>{:name=>"fk__course_lesson_plan_items_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_lesson_plan_items_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",             :null=>false, :index=>{:name=>"fk__course_lesson_plan_items_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_lesson_plan_items_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",             :null=>false
#   t.datetime "updated_at",             :null=>false
# end

# create_table "course_surveys", force: :cascade do |t|
#   t.boolean  "anonymous",                 :default=>false, :null=>false
#   t.boolean  "allow_modify_after_submit", :default=>false, :null=>false
#   t.boolean  "allow_response_after_end",  :default=>false, :null=>false
#   t.datetime "closing_reminded_at"
#   t.integer  "creator_id",                :null=>false, :index=>{:name=>"fk__course_surveys_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_surveys_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",                :null=>false, :index=>{:name=>"fk__course_surveys_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_surveys_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",                :null=>false
#   t.datetime "updated_at",                :null=>false
# end

# V1
# create_table "surveys", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.string   "title"
#   t.text     "description"
#   t.datetime "open_at"
#   t.datetime "expire_at"
#   t.boolean  "anonymous",    :default => false
#   t.boolean  "publish",      :default => true
#   t.boolean  "allow_modify", :default => true
#   t.boolean  "is_contest",   :default => false
#   t.time     "deleted_at"
#   t.datetime "created_at",                      :null => false
#   t.datetime "updated_at",                      :null => false
#   t.integer  "exp"
# end
