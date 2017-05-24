def transform_assessment_trq_questions(course_ids = [])
  transform_table :assessment_general_questions,
                  to: ::Course::Assessment::Question::TextResponse,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :assessment_id do
      original_assessment_id = source_record.assessment_question.assessments.first.id
      V1::Source::Assessment.transform(original_assessment_id)
    end
    column to: :title do
      source_record.assessment_question.title
    end
    column to: :description do
      description = ContentParser.parse_mc_tags(source_record.assessment_question.description)
      description, references = ContentParser.parse_images(source_record, description)
      self.question.attachment_references = references if references.any?
      description
    end
    column to: :maximum_grade do
      source_record.assessment_question.max_grade.to_i
    end
    column to: :weight do
      source_record.assessment_question.question_assessments.first.position || 0
    end
    column to: :creator_id do
      result = V1::Source::User.transform(source_record.assessment_question.creator_id)
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
# create_table "course_assessment_questions", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",        :limit=>255, :index=>{:name=>"index_course_assessment_questions_actable", :with=>["actable_id"], :unique=>true}
#   t.integer  "assessment_id",       :null=>false, :index=>{:name=>"fk__course_assessment_questions_assessment_id"}, :foreign_key=>{:references=>"course_assessments", :name=>"fk_course_assessment_questions_assessment_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "title",               :limit=>255
#   t.text     "description"
#   t.text     "staff_only_comments"
#   t.decimal  "maximum_grade",       :precision=>4, :scale=>1, :null=>false
#   t.integer  "weight",              :null=>false
#   t.integer  "creator_id",          :null=>false, :index=>{:name=>"fk__course_assessment_questions_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_questions_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",          :null=>false, :index=>{:name=>"fk__course_assessment_questions_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_questions_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",          :null=>false
#   t.datetime "updated_at",          :null=>false
# end
# create_table "course_assessment_question_text_responses", force: :cascade do |t|
# end


# V1
# create_table "assessment_questions", :force => true do |t|
#   t.integer  "as_question_id"
#   t.string   "as_question_type"
#   t.integer  "creator_id"
#   t.integer  "dependent_id"
#   t.string   "title"
#   t.text     "description"
#   t.float    "max_grade"
#   t.integer  "attempt_limit"
#   t.boolean  "file_submission",  :default => false
#   t.text     "staff_comments"
#   t.datetime "deleted_at"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
# end
# create_table "assessment_general_questions", :force => true do |t|
#   t.datetime "deleted_at"
#   t.datetime "created_at",                          :null => false
#   t.datetime "updated_at",                          :null => false
#   t.boolean  "auto_graded"
#   t.integer  "auto_grading_type_cd", :default => 0
#   t.text     "sample_answer"
# end