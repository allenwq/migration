module V1
  def_model 'seen_by_users' do
    belongs_to :obj, polymorphic: true, inverse_of: nil
    belongs_to :user_course, inverse_of: nil
  end
end

# create_table "seen_by_users", :force => true do |t|
#   t.integer  "user_course_id"
#   t.integer  "obj_id"
#   t.string   "obj_type"
#   t.datetime "created_at",     :null => false
#   t.datetime "updated_at",     :null => false
# end

# Possible `obj_type`s and number of records:
# ["Announcement", 166263],
# ["Assessment", 377026],
# ["Assessment::Submission", 136464],
# ["Comic", 18],
# ["ForumPost", 888199],
# ["ForumTopic", 106780],
# ["Notification", 154363],
# ["Training", 2243],
# ["TrainingSubmission", 225],
# ["Material", 146630],
# ["Mission", 550],
# ["Submission", 237]