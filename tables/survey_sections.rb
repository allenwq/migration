class SurveySectionTable < BaseTable
  table_name 'survey_sections'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Survey::Section.new

      migrate(old, new) do
        column :survey_id do
          store.get(V1::Survey.table_name, old.survey_id)
        end
        column :title do
          old.title || ''
        end
        column :description
        column :weight do
          old.pos || -1
        end

        # Skip the title blank validation
        new.save(validate: false)
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_survey_sections", force: :cascade do |t|
#   t.integer "survey_id",   :null=>false, :index=>{:name=>"fk__course_survey_sections_survey_id"}, :foreign_key=>{:references=>"course_surveys", :name=>"fk_course_survey_sections_survey_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string  "title",       :limit=>255, :null=>false
#   t.text    "description"
#   t.integer "weight",      :null=>false
# end

# V1
# create_table "survey_sections", :force => true do |t|
#   t.integer  "survey_id"
#   t.string   "title"
#   t.text     "description"
#   t.integer  "pos"
#   t.boolean  "publish",     :default => true
#   t.time     "deleted_at"
#   t.datetime "created_at",                    :null => false
#   t.datetime "updated_at",                    :null => false
# end