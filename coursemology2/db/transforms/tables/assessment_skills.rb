def transform_assessment_skills(course_ids = [])
  transform_table :tag_groups,
                  to: ::Course::Assessment::SkillBranch,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column :name, to: :title
    column :description, to: :description do |description|
      description.present? ? description : '( No Description )'
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end

  transform_table :tags,
                  to: ::Course::Assessment::Skill,
                  default_scope: proc { within_courses(course_ids) } do
    primary_key :id
    column to: :course_id do
      CoursemologyV1::Source::Course.transform(source_record.course_id)
    end
    column to: :skill_branch_id do
      CoursemologyV1::Source::TagGroup.transform(source_record.tag_group_id)
    end
    column :name, to: :title
    column :description, to: :description do |description|
      description.present? ? description : '( no description )'
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
  end

  transform_table :taggable_tags, to: :course_assessment_questions_skills,
                  default_scope: proc { within_courses(course_ids).find_each } do
    primary_key :id
    column to: :question_id do
      if source_record.taggable_type == 'Assessment::Question'
        CoursemologyV1::Source::AssessmentQuestion.transform(source_record.taggable_id)
      end
    end
    column to: :skill_id do
      CoursemologyV1::Source::Tag.transform(source_record.tag_id)
    end

    save validate: false, if: proc {
      if question_id && skill_id
        true
      else
        puts "Invalid #{source_record.class} #{source_record.primary_key_value}:"\
        " question_id: #{question_id}, skill_id: #{skill_id}"
        false
      end
    }
  end
end

# Schema
#
# V2:
# create_table "course_assessment_skill_branches", force: :cascade do |t|
#   t.integer  "course_id",   null: false, index: {name: "fk__course_assessment_skill_branches_course_id"}, foreign_key: {references: "courses", name: "fk_course_assessment_skill_branches_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",       limit: 255, null: false
#   t.text     "description", null: false
#   t.integer  "creator_id",  null: false, index: {name: "fk__course_assessment_skill_branches_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessment_skill_branches_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",  null: false, index: {name: "fk__course_assessment_skill_branches_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessment_skill_branches_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",  null: false
#   t.datetime "updated_at",  null: false
# end
#
# create_table "course_assessment_skills", force: :cascade do |t|
#   t.integer  "course_id",       null: false, index: {name: "fk__course_assessment_skills_course_id"}, foreign_key: {references: "courses", name: "fk_course_assessment_skills_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "skill_branch_id", index: {name: "fk__course_assessment_skills_skill_branch_id"}, foreign_key: {references: "course_assessment_skill_branches", name: "fk_course_assessment_skills_skill_branch_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",           limit: 255, null: false
#   t.text     "description",     null: false
#   t.integer  "creator_id",      null: false, index: {name: "fk__course_assessment_skills_creator_id"}, foreign_key: {references: "users", name: "fk_course_assessment_skills_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",      null: false, index: {name: "fk__course_assessment_skills_updater_id"}, foreign_key: {references: "users", name: "fk_course_assessment_skills_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",      null: false
#   t.datetime "updated_at",      null: false
# end
#
# create_table "course_assessment_questions_skills", force: :cascade do |t|
#   t.integer "question_id", null: false, index: {name: "course_assessment_question_skills_question_index"}, foreign_key: {references: "course_assessment_questions", name: "fk_course_assessment_questions_skills_question_id", on_update: :no_action, on_delete: :no_action}
#   t.integer "skill_id",    null: false, index: {name: "course_assessment_question_skills_skill_index"}, foreign_key: {references: "course_assessment_skills", name: "fk_course_assessment_questions_skills_skill_id", on_update: :no_action, on_delete: :no_action}
# end

# V1
# create_table "tag_groups", :force => true do |t|
#   t.string   "name"
#   t.text     "description"
#   t.integer  "course_id"
#   t.datetime "created_at",  :null => false
#   t.datetime "updated_at",  :null => false
#   t.time     "deleted_at"
# end
#
# add_index "tag_groups", ["course_id"], :name => "index_tag_groups_on_course_id"
#
# create_table "taggable_tags", :force => true do |t|
#   t.string   "taggable_type"
#   t.integer  "taggable_id"
#   t.integer  "tag_id"
#   t.datetime "deleted_at"
#   t.datetime "created_at",    :null => false
#   t.datetime "updated_at",    :null => false
# end
#
# create_table "tags", :force => true do |t|
#   t.string   "name"
#   t.integer  "taggings_count", :default => 0
#   t.text     "description"
#   t.integer  "course_id"
#   t.integer  "tag_group_id"
#   t.datetime "deleted_at"
#   t.datetime "created_at"
#   t.datetime "updated_at"
# end