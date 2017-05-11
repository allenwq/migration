def transform_survey_sections(course_ids = [])
  transform_table :survey_sections,
                  to: ::Course::Survey::Section,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :survey_id, to: :survey_id do |survey_id|
      V1::Source::Survey.transform(survey_id)
    end
    column :title, to: :title do |title|
      title || ''
    end
    column :description
    column :pos, to: :weight do |pos|
      pos || -1
    end

    # Skip the title blank validation
    save validate: false
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