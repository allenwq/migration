class AssessmentProgrammingQuestionTable < BaseTable
  table_name 'assessment_coding_questions'
  scope { |ids| within_courses(ids).includes(:assessment_question) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Assessment::Question::Programming.new
      build_programming_package(old, new)

      migrate(old, new) do
        column :assessment_id do
          original_assessment_id = old.assessment_question.assessments.first.id
          store.get(V1::Assessment.table_name, original_assessment_id)
        end
        column :description do
          description = ContentParser.parse_mc_tags(old.assessment_question.description)
          description, references = ContentParser.parse_images(old, description, logger)
          new.question.attachment_references = references if references.any?
          description
        end
        column :staff_only_comments do
          old.assessment_question.staff_comments
        end
        column :maximum_grade do
          old.assessment_question.max_grade.to_i
        end
        column :weight do
          old.assessment_question.question_assessments.first.position || 0
        end
        column :title do
          old.assessment_question.title
        end
        column :language_id do
          # V1: 1 => python3.3, 2 => python3.4, 3 => python2.7, 4 => python3.5
          # V2: 1 => JavaScript, 2 => Python 2.7, 3=>Python 3.4, 4=>Python 3.5, 5=>Python 3.6, 6=>C/C++
          case old.language_id
          when 1, 2
            3
          when 3
            2
          when 4
            4
          else
            5
          end
        end
        column :memory_limit do
          if old.memory_limit
            # 22 - 50 is minimal memory required from manual tests, use 50 for safe.
            old.memory_limit + 50
          else
            nil
          end
        end
        column :time_limit do
          if old.time_limit && old.time_limit <= 30 && old.time_limit > 0
            old.time_limit
          else
            nil
          end
        end
        column :attempt_limit do
          old.assessment_question.attempt_limit
        end
        column :creator_id do
          result = store.get(V1::User.table_name, old.assessment_question.creator_id)
          result
        end
        new.updater_id = new.creator_id
        column :updated_at
        column :created_at

        skip_saving_unless_valid

        store.set(V1::AssessmentQuestion.table_name, old.assessment_question.id, new.acting_as.id)
        store.set(model.table_name, old.id, new.id)
      end
    end
  end

  def build_programming_package(old, new)
    # Migrate programming package
    tests = old.tests.present? ? JSON.parse(old.tests) : {}
    public_tests = []
    private_tests = []
    eval_tests = []
    identifer_prefix = 'AutoGrader/AutoGrader/'

    tests['public'] && tests['public'].each.with_index(1) do |test, index|
      public_tests << {
        expected: test['expected'],
        expression: test['expression']
      }

      new.test_cases.build(
        identifier: "#{identifer_prefix}test_public_#{format('%02i', index)}",
        test_case_type: 'public_test',
        expression: test['expression'],
        expected: test['expected']
      )
    end

    tests['private'] && tests['private'].each.with_index(1) do |test, index|
      private_tests << {
        expected: test['expected'],
        expression: test['expression'],
        hint: test['hint']
      }

      new.test_cases.build(
        identifier: "#{identifer_prefix}test_private_#{format('%02i', index)}",
        test_case_type: 'private_test',
        expression: test['expression'],
        expected: test['expected'],
        hint: test['hint']
      )
    end

    tests['eval'] && tests['eval'].each.with_index(1) do |test, index|
      eval_tests << {
        expected: test['expected'],
        expression: test['expression'],
        hint: test['hint']
      }

      new.test_cases.build(
        identifier: "#{identifer_prefix}test_evaluation_#{format('%02i', index)}",
        test_case_type: 'evaluation_test',
        expression: test['expression'],
        expected: test['expected'],
        hint: test['hint']
      )
    end

    data_files = []
    # Find the orignal assessment
    origin_assessment = old.assessment
    origin_assessment && origin_assessment.file_uploads.each do |file|
      next if file.original_name.end_with?('.pdf')

      local_file = file.download_to_local(logger)
      tmp_file = Rack::Test::UploadedFile.new(local_file.path)
      # The default name is a random hash
      tmp_file.instance_variable_set(:@original_filename, file.original_name)
      local_file.close
      data_files << tmp_file
    end
    params = {
      prepend: old.pre_include,
      append: old.append_code,
      submission: old.template,
      solution: nil,
      autograded: old.auto_graded,
      data_files: data_files,
      test_cases: {
        public: public_tests,
        private: private_tests,
        evaluation: eval_tests
      }
    }

    params = ActionController::Parameters.new(question_programming: params)
    service = ::Course::Assessment::Question::Programming::Python::PythonPackageService.new(params)

    templates = service.submission_templates

    if old.auto_graded
      new.file = service.generate_package(nil)
      new.template_files = templates.map do |template|
        Course::Assessment::Question::ProgrammingTemplateFile.new(template)
      end
    else
      new.imported_attachment = nil
      new.import_job_id = nil
      new.non_autograded_template_files = templates.map do |template|
        Course::Assessment::Question::ProgrammingTemplateFile.new(template)
      end
    end

    new.package_type = :online_editor
    data_files.each(&:close)
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
# create_table "course_assessment_question_programming", force: :cascade do |t|
#   t.integer "language_id",   :null=>false, :index=>{:name=>"fk__course_assessment_question_programming_language_id"}, :foreign_key=>{:references=>"polyglot_languages", :name=>"fk_course_assessment_question_programming_language_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer "memory_limit",  :comment=>"Memory limit, in MiB"
#   t.integer "time_limit",    :comment=>"Time limit, in seconds"
#   t.integer "attempt_limit"
#   t.uuid    "import_job_id", :comment=>"The ID of the importing job", :index=>{:name=>"index_course_assessment_question_programming_on_import_job_id", :unique=>true}, :foreign_key=>{:references=>"jobs", :name=>"fk_course_assessment_question_programming_import_job_id", :on_update=>:no_action, :on_delete=>:nullify}
#   t.integer "package_type",  :default=>0, :null=>false
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
# create_table "assessment_coding_questions", :force => true do |t|
#   t.integer  "language_id"
#   t.boolean  "auto_graded"
#   t.text     "tests"
#   t.integer  "memory_limit"
#   t.integer  "time_limit"
#   t.text     "template"
#   t.text     "pre_include"
#   t.text     "append_code"
#   t.datetime "deleted_at"
#   t.datetime "created_at",   :null => false
#   t.datetime "updated_at",   :null => false
# end
