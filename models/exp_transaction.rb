module V1
  def_model 'exp_transactions' do
    belongs_to :user_course, inverse_of: nil

    scope :within_courses, ->(course_ids) {
      joins(:user_course).where(user_course: { course_id: course_ids }).
        where(rewardable_id: nil) # Manually awarded exp
    }
  end

  ::Course::ExperiencePointsRecord.class_eval do
    def send_notification
    end

    # The method was used to send notification, skip to save one query.
    def reached_new_level?
    end

    # should not set the attirbutes by magic, instead the migration should handle.
    def set_awarded_attributes
    end
  end
end

# create_table "exp_transactions", :force => true do |t|
#   t.integer  "exp"
#   t.string   "reason"
#   t.boolean  "is_valid"
#   t.integer  "user_course_id"
#   t.integer  "giver_id"
#   t.datetime "created_at",      :null => false
#   t.datetime "updated_at",      :null => false
#   t.time     "deleted_at"
#   t.integer  "rewardable_id"
#   t.string   "rewardable_type"
# end