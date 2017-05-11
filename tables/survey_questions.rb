def transform_survey_questions(course_ids = [])
  transform_table :survey_questions,
                  to: ::Course::Survey::Question,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :survey_section_id, to: :section_id do |id|
      V1::Source::SurveySection.transform(id)
    end
    column :type_id, to: :question_type do |id|
      # V2 types
      # question_type: { text: 0, multiple_choice: 1, multiple_response: 2 }
      case id
      when 1
        :multiple_choice
      when 2
        :multiple_response
      when 3
        :text
      end
    end
    column :description, to: :description do |title|
      title || ''
    end
    column :pos, to: :weight do |pos|
      pos || -1
    end
    column :is_required, to: :required
    column :max_response, to: :max_options

    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end
end

def transform_survey_question_options(course_ids = [])
  transform_table :survey_question_options,
                  to: ::Course::Survey::QuestionOption,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column :question_id, to: :question_id do |id|
      V1::Source::SurveyQuestion.transform(id)
    end
    column :description, to: :option do |description|
      description || ''
    end
    column :pos, to: :weight do |pos|
      pos || -1
    end

    # Consider adding timestamps in v2..
    # column :updated_at
    # column :created_at

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_survey_questions", force: :cascade do |t|
#   t.integer  "section_id",    :null=>false, :index=>{:name=>"index_course_survey_questions_on_section_id"}, :foreign_key=>{:references=>"course_survey_sections", :name=>"fk_course_survey_questions_section_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "question_type", :default=>0, :null=>false
#   t.text     "description",   :null=>false
#   t.integer  "weight",        :null=>false
#   t.boolean  "required",      :default=>false, :null=>false
#   t.boolean  "grid_view",     :default=>false, :null=>false
#   t.integer  "max_options"
#   t.integer  "min_options"
#   t.integer  "creator_id",    :null=>false, :index=>{:name=>"fk__course_survey_questions_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_questions_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",    :null=>false, :index=>{:name=>"fk__course_survey_questions_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_survey_questions_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",    :null=>false
#   t.datetime "updated_at",    :null=>false
# end

# create_table "course_survey_question_options", force: :cascade do |t|
#   t.integer "question_id", :null=>false, :index=>{:name=>"fk__course_survey_question_options_question_id"}, :foreign_key=>{:references=>"course_survey_questions", :name=>"fk_course_survey_question_options_question_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.text    "option"
#   t.integer "weight",      :null=>false
# end

# V1
# create_table "survey_questions", :force => true do |t|
#   t.integer  "type_id"
#   t.integer  "survey_id"
#   t.integer  "survey_section_id"
#   t.text     "description"
#   t.boolean  "publish",           :default => true
#   t.integer  "max_response"
#   t.integer  "pos"
#   t.time     "deleted_at"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
#   t.boolean  "is_required",       :default => true
# end

# create_table "survey_question_options", :force => true do |t|
#   t.integer  "question_id"
#   t.text     "description"
#   t.time     "deleted_at"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
#   t.integer  "pos"
#   t.integer  "count", this is the number of total selections of students' answers... can be ignored
# end