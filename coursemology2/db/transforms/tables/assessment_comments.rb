def transform_assessment_comments(course_ids = [])
  transform_table :comments,
                  to: ::Course::Discussion::Post,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :topic_id do
      source_record.transform_topic_id
    end
    column to: :title do
      '(No Title)'
    end
    column to: :text do
      ContentParser.parse_mc_tags(source_record.text)
    end
    column to: :creator_id do
      result = source_record.transform_creator_id
      self.updater_id = result
      result
    end
    column :created_at
    column :updated_at

    skip_saving_unless_valid do
      # Drop those records without creator
      if creator_id.present?
        valid?
      else
        errors.add(:creator, :blank)
        false
      end
    end
  end

  transform_table :annotations,
                  to: ::Course::Discussion::Post,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :topic do
      file = source_record.transform_file
      if file
        new_course_id = CoursemologyV1::Source::Course.transform(source_record.assessment_answer.std_course.course_id)
        Course::Assessment::Answer::ProgrammingFileAnnotation.
          new(file: file, line: source_record.line_start, course_id: new_course_id).discussion_topic
      end
    end
    column to: :title do
      '(No Title)'
    end
    column to: :text do
      ContentParser.parse_mc_tags(source_record.text)
    end
    column to: :creator_id do
      result = source_record.transform_creator_id
      self.updater_id = result
      result
    end
    column :created_at
    column :updated_at

    skip_saving_unless_valid do
      # Drop those records without creator
      if creator_id.present?
        valid?
      else
        errors.add(:creator, :blank)
        false
      end
    end
  end
end

# Schema
#
# V2:
#
# create_table "course_assessment_answer_programming_file_annotations", force: :cascade do |t|
#   t.integer "file_id", null: false, index: {name: "fk__course_assessment_answe_09c4b638af92d0f8252d7cdef59bd6f3"}, foreign_key: {references: "course_assessment_answer_programming_files", name: "fk_course_assessment_answer_ed21459e7a2a5034dcf43a14812cb17d", on_update: :no_action, on_delete: :no_action}
#   t.integer "line",    null: false
# end
#
# create_table "course_discussion_topics", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",        limit: 255, index: {name: "index_course_discussion_topics_on_actable_type_and_actable_id", with: ["actable_id"], unique: true}
#   t.integer  "course_id",           null: false, index: {name: "fk__course_discussion_topics_course_id"}, foreign_key: {references: "courses", name: "fk_course_discussion_topics_course_id", on_update: :no_action, on_delete: :no_action}
#   t.boolean  "pending_staff_reply", default: false, null: false
#   t.datetime "created_at",          null: false
#   t.datetime "updated_at",          null: false
# end

# V1:
#
# create_table "comment_topics", :force => true do |t|
#   t.integer  "course_id"
#   t.integer  "topic_id"
#   t.string   "topic_type" // Assessment::Answer, etc.. Duplicated with commentable_id and annotable_id
#   t.datetime "last_commented_at"
#   t.boolean  "pending"
#   t.string   "permalink"
#   t.datetime "created_at",        :null => false
#   t.datetime "updated_at",        :null => false
# end
#
# create_table "comments", :force => true do |t|
#   t.integer  "user_course_id"
#   t.text     "text"
#   t.integer  "commentable_id"
#   t.string   "commentable_type"
#   t.datetime "created_at",       :null => false
#   t.datetime "updated_at",       :null => false
#   t.time     "deleted_at"
#   t.integer  "comment_topic_id"
# end
#
# create_table "annotations", :force => true do |t|
#   t.integer  "annotable_id"
#   t.string   "annotable_type"
#   t.integer  "line_start"
#   t.integer  "line_end"
#   t.integer  "user_course_id"
#   t.text     "text"
#   t.datetime "created_at",     :null => false
#   t.datetime "updated_at",     :null => false
#   t.time     "deleted_at"
# end