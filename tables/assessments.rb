class AssessmentTable < BaseTable
  table_name 'assessments'
  scope { |ids| within_courses(ids).includes(:as_assessment) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment.new
      migrate(old, new) do
        column :course_id do
          id = store.get(V1::Course.table_name, old.course_id)
          new.folder.course_id = id
          id
        end
        column :title do
          old.title.present? ? old.title : 'Untitled'
        end
        column :description do
          description = ContentParser.parse_mc_tags(old.description)
          description, references = ContentParser.parse_images(old, description)
          new.attachment_references = references if references.any?
          description
        end
        column :base_exp do
          old.exp || 0
        end
        column :time_bonus_exp do
          old.bonus_exp || 0
        end
        column :open_at => :start_at
        column :close_at => :end_at
        column :bonus_cutoff_at => :bonus_end_at
        column :published
        column :autograded do
          if old.as_assessment_type == 'Assessment::Training'
            true
          elsif old.as_assessment_type == 'Assessment::Mission'
            false
          end
        end
        column :skippable do
          if old.as_assessment_type == 'Assessment::Training'
            old.specific.skippable
          else
            false
          end
        end
        column :tabbed_view do
          # display_mode_id: 1 = > single page, 2 => tab
          if old.as_assessment_type == 'Assessment::Mission' && old.display_mode_id == 2
            true
          else
            false
          end
        end
        column :tab_id do
          assessment_infer_new_tab_id(old, new)
        end
        column :creator_id do
          result = store.get(V1::User.table_name, old.creator_id)
          new.updater_id = result
          result
        end
        column :updated_at do
          updated_at = old.updated_at
          new.lesson_plan_item.updated_at = updated_at
          new.folder.updated_at = updated_at
          updated_at
        end
        column :created_at do
          created_at = old.created_at
          new.lesson_plan_item.created_at = created_at
          new.folder.created_at = created_at
          created_at
        end

        names = []
        old.file_uploads.visible.each do |file|
          attachment = file.transform_attachment_reference(store)
          if attachment
            name = get_valid_name(Pathname.normalize_filename(attachment.name), names)
            m = new.folder.materials.build(attachment_reference: attachment, name: name,
                                           created_at: attachment.created_at, updated_at: attachment.updated_at,
                                           creator_id: attachment.creator_id, updater_id: attachment.updater_id)
            names << m.name
          end
        end

        if old.file_upload_enabled?
          new.questions << build_file_upload_question(new).acting_as
        end

        skip_saving_unless_valid

        store.set(model.table_name, old.id, new.id)
      end
    end
  end

  def assessment_infer_new_tab_id(old, new)
    # Some assessment has a tab id of 0...
    return store.get(V1::Tab.table_name, old.tab_id) if old.tab_id && old.tab_id > 0

    # Try to assign to default tab
    new_course = Course.find(store.get(V1::Course.table_name, old.course_id))
    # Training's category in the new course is the first, mission category is the second, so we
    # need to unscope the default order by weight.
    if old.as_assessment_type == 'Assessment::Training'
      new_course.assessment_categories.unscope(:order).first.tabs.first.id
    elsif old.as_assessment_type == 'Assessment::Mission'
      new_course.assessment_categories.unscope(:order).last.tabs.first.id
    end
  end

  def get_valid_name(base_name, existing_names)
    names_taken = existing_names.map(&:downcase)
    name_generator = FileName.new(
      base_name, path: :relative, position: :prefix, add: :always, format: '(%d)', delimiter: ' ',
      filter: { after: lambda { |basename| basename } } # Needed to remove `./` in the front
    )
    new_name = base_name
    new_name = name_generator.create while names_taken.include?(new_name.downcase)

    new_name
  end

  def build_file_upload_question(assessment)
    question = Course::Assessment::Question::TextResponse.new(hide_text: true, allow_attachment: true)
    question.title = 'File Upload'
    question.maximum_grade = 0
    question.weight = 100 # using a higher weight to make it last
    question.created_at = assessment.created_at
    question.updated_at = assessment.created_at
    question.creator_id = assessment.creator_id
    question.updater_id = assessment.creator_id
    question
  end
end

# Schema
#
# V2:
# create_table "course_lesson_plan_items", force: :cascade do |t|
#   t.integer  "actable_id"
#   t.string   "actable_type",    limit: 255, index: {name: "index_course_lesson_plan_items_on_actable_type_and_actable_id", with: ["actable_id"], unique: true}
#   t.integer  "course_id",       null: false, index: {name: "fk__course_lesson_plan_items_course_id"}, foreign_key: {references: "courses", name: "fk_course_lesson_plan_items_course_id", on_update: :no_action, on_delete: :no_action}
#   t.string   "title",           limit: 255,                 null: false
#   t.text     "description"
#   t.boolean  "draft",           default: false, null: false
#   t.integer  "base_exp",        null: false
#   t.integer  "time_bonus_exp",  null: false
#   t.datetime "start_at",        null: false
#   t.datetime "bonus_end_at"
#   t.datetime "end_at"
#   t.integer  "creator_id",      null: false, index: {name: "fk__course_lesson_plan_items_creator_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_items_creator_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "updater_id",      null: false, index: {name: "fk__course_lesson_plan_items_updater_id"}, foreign_key: {references: "users", name: "fk_course_lesson_plan_items_updater_id", on_update: :no_action, on_delete: :no_action}
#   t.datetime "created_at",      null: false
#   t.datetime "updated_at",      null: false
# end

# create_table "course_assessments", force: :cascade do |t|
#   t.integer  "tab_id",                    :null=>false, :index=>{:name=>"fk__course_assessments_tab_id"}, :foreign_key=>{:references=>"course_assessment_tabs", :name=>"fk_course_assessments_tab_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.boolean  "tabbed_view",               :default=>false, :null=>false
#   t.boolean  "autograded",                :null=>false
#   t.boolean  "skippable",                 :default=>false
#   t.boolean  "delayed_grade_publication", :default=>false
#   t.string   "password",                  :limit=>255
#   t.integer  "creator_id",                :null=>false, :index=>{:name=>"fk__course_assessments_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessments_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",                :null=>false, :index=>{:name=>"fk__course_assessments_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_course_assessments_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",                :null=>false
#   t.datetime "updated_at",                :null=>false
# end

# V1
# create_table "assessments", :force => true do |t|
#   t.integer  "as_assessment_id",                     :null => false
#   t.string   "as_assessment_type",                   :null => false
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.integer  "tab_id"
#   t.string   "title"
#   t.text     "description"
#   t.integer  "position"
#   t.integer  "exp"
#   t.float    "max_grade"
#   t.boolean  "published"
#   t.boolean  "comment_per_qn",     :default => true
#   t.integer  "display_mode_id"
#   t.integer  "bonus_exp"
#   t.datetime "bonus_cutoff_at"
#   t.datetime "open_at"
#   t.datetime "close_at"
#   t.datetime "deleted_at"
#   t.datetime "created_at",                           :null => false
#   t.datetime "updated_at",                           :null => false
# end
# create_table "assessment_missions", :force => true do |t|
#   t.boolean  "file_submission",      :default => false
#   t.boolean  "file_submission_only", :default => false
#   t.datetime "deleted_at"
#   t.datetime "created_at",                              :null => false
#   t.datetime "updated_at",                              :null => false
# end
#
# create_table "assessment_trainings", :force => true do |t|
#   t.boolean  "skippable"
#   t.datetime "deleted_at"
#   t.datetime "created_at", :null => false
#   t.datetime "updated_at", :null => false
# end