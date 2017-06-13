class AssessmentSkillGroupTable < BaseTable
  table_name 'tag_groups'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::SkillBranch.new

      # Skip migrate the magic uncategorized category
      if old.name == 'Uncategorized'
        store.set(model.table_name, old.id, 'NULL')
        next
      end

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :name => :title
        column :description
        column :updated_at
        column :created_at

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class AssessmentSkillTable < BaseTable
  table_name 'tags'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Skill.new

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :skill_branch_id do
          id = store.get(V1::TagGroup.table_name, old.tag_group_id)
          id == 'NULL' ? nil : id
        end
        column :name => :title
        column :description
        column :updated_at
        column :created_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

class AssessmentQuestionSkillTable < BaseTable
  table_name 'taggable_tags'
  scope { |ids| within_courses(ids) }

  class QuestionSkill < ActiveRecord::Base
    self.table_name = 'course_assessment_questions_skills'
  end

  def migrate_batch(batch)
    batch.each do |old|
      new = QuestionSkill.new

      migrate(old, new) do
        column :question_id do
          store.get(V1::AssessmentQuestion.table_name, old.taggable_id)
        end
        column :skill_id do
          store.get(V1::Tag.table_name, old.tag_id)
        end

        if new.question_id && new.skill_id
          new.save(validate: false)
          store.set(model.table_name, old.id, new.id)
        else
          logger.log "Invalid #{old.class} #{old.primary_key_value}: question_id: #{new.question_id}, skill_id: #{new.skill_id}"
        end
      end
    end
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