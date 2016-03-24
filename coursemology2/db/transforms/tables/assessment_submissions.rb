def transform_assessment_submissions(course_ids = [])
  transform_table :assessment_submissions,
                  to: ::Course::Assessment::Submission,
                  default_scope: proc { includes(:std_course).within_courses(course_ids).find_each } do
    primary_key :id
    column :std_course_id, to: :course_user_id do |std_course_id|
      CoursemologyV1::Source::UserCourse.transform(std_course_id)
    end
    column to: :assessment_id do
      CoursemologyV1::Source::Assessment.transform(source_record.assessment_id)
    end
    column to: :workflow_state do
      # V1: 'attempting', 'submitted', 'graded'
      # V2:
      #   state :attempting
      #   state :submitted
      #   state :graded
      case source_record.status
      when 'graded'
        :graded
      when 'attempting'
        :attempting
      when 'submitted'
        :submitted
      end
    end
    column to: :points_awarded do
      source_record.exp_awarded
    end
    column to: :creator_id do
      CoursemologyV1::Source::User.transform(source_record.std_course.user_id)
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end
end

# Schema
#
# V2:
# create_table "course_assessment_submissions", force: :cascade do |t|
#   t.integer  "assessment_id",  null: false, index: {name: "fk__course_assessment_submissions_assessment_id"}, foreign_key: {references: "course_assessments", name: "fk_course_assessment_submissions_assessment_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "workflow_state", limit: 255, null: false
#   t.integer  "creator_id",     null: false, index: {name: "fk__course_assessment_submissions_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessment_submissions_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",     null: false, index: {name: "fk__course_assessment_submissions_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessment_submissions_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",     null: false
#   t.datetime "updated_at",     null: false
# end
# create_table "course_experience_points_records", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",   limit: 255, index: {name: "index_course_experience_points_records_on_actable", with: ["actable_id"], unique: true}
#   t.integer  "points_awarded"
#   t.integer  "course_user_id", null: false, index: {name: "fk__course_experience_points_records_course_user_id"}, foreign_key: {references: "course_users", name: "fk_course_experience_points_records_course_user_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "reason",         limit: 255
#   t.integer  "creator_id",     null: false, index: {name: "fk__course_experience_points_records_creator_id"}, foreign_key: {references: "users", name: "fk_course_experience_points_records_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",     null: false, index: {name: "fk__course_experience_points_records_updater_id"}, foreign_key: {references: "users", name: "fk_course_experience_points_records_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",     null: false
#   t.datetime "updated_at",     null: false
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