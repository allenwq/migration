class AssessmentAnswerScribbleTable < BaseTable
  table_name 'scribbles'
  scope { |ids| within_courses(ids).includes(:user_course) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Answer::ScribingScribble.new

      migrate(old, new) do
        column :answer_id do
          store.get(V1::AssessmentScribingAnswer.table_name, old.scribing_answer_id)
        end
        column :creator_id do
          store.get(V1::User.table_name, old.user_course.user_id)
        end

        column :content
        column :updated_at
        column :created_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_assessment_answer_scribing_scribbles", force: :cascade do |t|
#   t.text     "content"
#   t.integer  "answer_id",  :index=>{:name=>"fk__course_assessment_answer_scribing_scribbles_scribing_answer"}, :foreign_key=>{:references=>"course_assessment_answer_scribings", :name=>"fk_course_assessment_answer_scribing_scribbles_answer_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "creator_id", :null=>false, :index=>{:name=>"fk__course_assessment_answer_scribing_scribbles_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_answer_scribing_scribbles_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at", :null=>false
#   t.datetime "updated_at", :null=>false
# end

# V1
# create_table "scribbles", :force => true do |t|
#   t.text     "content",            :limit => 16777215
#   t.integer  "std_course_id"
#   t.integer  "scribing_answer_id",  points to scribing_answers table
#   t.datetime "created_at",                             :null => false
#   t.datetime "updated_at",                             :null => false
# end
