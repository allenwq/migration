class AssessmentSubmissionTable < BaseTable
  table_name 'assessment_submissions'
  scope { |ids| within_courses(ids).includes(:std_course) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Submission.new
      
      migrate(old, new) do
        column :course_user_id do
          store.get(V1::UserCourse.table_name, old.std_course_id)
        end
        column :assessment_id do
          store.get(V1::Assessment.table_name, old.assessment_id)
        end
        column :workflow_state do
          # V1: 'attempting', 'submitted', 'graded'
          # V2:
          #   state :attempting
          #   state :submitted
          #   state :graded
          #   state :published
          case old.status
          when 'graded'
            :published
          when 'attempting'
            :attempting
          when 'submitted'
            :submitted
          end
        end
        column :points_awarded do
          old.exp_awarded
        end
        column :submitted_at do
          if old.submitted_at
            old.submitted_at
          elsif old.status == 'submitted' || old.status == 'graded'
            # in case source data is broken, use updated_at as submitted at
            old.updated_at
          end
        end
        column :published_at do
          old.published_at
        end
        column :publisher_id do
          if old.publisher_id
            store.get(V1::User.table_name, old.publisher_id) || User.deleted.id
          elsif old.status == 'graded'
            # in V1 the grader_id is nil for trainings
            ::User.system.id
          end
        end
        column :awarder_id do
          new.publisher_id
        end
        column :awarded_at do
          new.published_at
        end

        column :creator_id do
          result = store.get(V1::User.table_name, old.std_course.user_id)
          new.updater_id = result
          result
        end
        column :updated_at
        column :created_at

        new.acting_as.updated_at = old.updated_at
        new.acting_as.created_at = old.created_at

        if old.assessment.file_upload_enabled?
          new.answers << build_file_upload_answer(store, old, new).acting_as
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id) if new.persisted?
      end
    end
  end

  def build_file_upload_answer(store, old_submission, new_submission)
    answer = ::Course::Assessment::Answer::TextResponse.new
    answer.question = new_submission.assessment.questions.map(&:specific).detect { |q| q.try(:file_upload_question?) }.acting_as
    answer.created_at = new_submission.created_at
    answer.updated_at = new_submission.updated_at
    answer.workflow_state = case old_submission.status
                            when 'graded'
                              :graded
                            when 'submitted'
                              :submitted
                            else
                              :attempting
                            end
    if !answer.attempting?
      answer.submitted_at = old_submission.submitted_at
    end
    if answer.graded?
      answer.grade = 0
      answer.graded_at = new_submission.published_at
      answer.grader_id = new_submission.publisher_id
    end
    old_submission.file_uploads.each do |file|
      attachment = file.transform_attachment_reference(store, logger)
      answer.attachment_references << attachment if attachment
    end

    answer
  end
end

# Schema
#
# V2:
# create_table "course_assessment_submissions", force: :cascade do |t|
#   t.integer  "assessment_id",  :null=>false, :index=>{:name=>"fk__course_assessment_submissions_assessment_id"}, :foreign_key=>{:references=>"course_assessments", :name=>"fk_course_assessment_submissions_assessment_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "workflow_state", :limit=>255, :null=>false
#   t.string   "session_id",     :limit=>255
#   t.integer  "publisher_id",   :index=>{:name=>"fk__course_assessment_submissions_publisher_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_submissions_publisher_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "published_at"
#   t.datetime "submitted_at"
#   t.integer  "creator_id",     :null=>false, :index=>{:name=>"fk__course_assessment_submissions_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_submissions_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",     :null=>false, :index=>{:name=>"fk__course_assessment_submissions_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessment_submissions_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",     :null=>false
#   t.datetime "updated_at",     :null=>false
# end
# create_table "course_experience_points_records", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",         :limit=>255, :index=>{:name=>"index_course_experience_points_records_on_actable", :with=>["actable_id"], :unique=>true}
#   t.integer  "draft_points_awarded"
#   t.integer  "points_awarded"
#   t.integer  "course_user_id",       :null=>false, :index=>{:name=>"fk__course_experience_points_records_course_user_id"}, :foreign_key=>{:references=>"course_users", :name=>"fk_course_experience_points_records_course_user_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "reason",               :limit=>255
#   t.integer  "awarder_id",           :index=>{:name=>"fk__course_experience_points_records_awarder_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_awarder_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "awarded_at"
#   t.integer  "creator_id",           :null=>false, :index=>{:name=>"fk__course_experience_points_records_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",           :null=>false, :index=>{:name=>"fk__course_experience_points_records_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_experience_points_records_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",           :null=>false
#   t.datetime "updated_at",           :null=>false
# end

# V1
# create_table "assessment_submissions", :force => true do |t|
#   t.integer  "assessment_id"
#   t.integer  "std_course_id"
#   t.string   "status"
#   t.float    "multiplier"
#   t.datetime "opened_at"
#   t.datetime "submitted_at"
#   t.datetime "deleted_at"
#   t.datetime "created_at",    :null => false
#   t.datetime "updated_at",    :null => false
#   t.datetime "saved_at"
# end
# create_table "assessment_gradings", :force => true do |t|
#   t.integer  "submission_id"
#   t.integer  "grader_id"
#   t.integer  "grader_course_id"
#   t.integer  "std_course_id"
#   t.float    "grade"
#   t.integer  "exp"
#   t.integer  "exp_transaction_id"
#   t.boolean  "autograding_refresh", :default => false
#   t.datetime "deleted_at"
#   t.datetime "created_at",                             :null => false
#   t.datetime "updated_at",                             :null => false
# end