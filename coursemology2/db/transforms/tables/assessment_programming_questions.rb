def transform_assessment_programming_questions(course_ids = [])
  transform_table :assessment_coding_questions,
                  to: ::Course::Assessment::Question::Programming,
                  default_scope: proc { within_courses(course_ids).includes(:assessment_question) } do
    before_transform do |old, new|
      # Migrate programming package
      tests = old.tests.present? ? JSON.parse(old.tests) : {}
      public_tests = []
      private_tests = []
      eval_tests = []

      tests['public'] && tests['public'].each.with_index(1) do |test, index|
          public_tests << {
            expected: test['expected'],
            expression: test['expression']
          }

          new.test_cases.build(
            identifier: "test_public_#{format('%02i', index)}",
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
          identifier: "test_private_#{format('%02i', index)}",
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
          identifier: "test_evaluation_#{format('%02i', index)}",
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

        local_file = file.download_to_local
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
      true
    end

    primary_key :id
    column to: :assessment_id do
      original_assessment_id = source_record.assessment_question.assessments.first.id
      V1::Source::Assessment.transform(original_assessment_id)
    end
    column to: :description do
      description = ContentParser.parse_mc_tags(source_record.assessment_question.description)
      description, references = ContentParser.parse_images(source_record, description)
      self.question.attachment_references = references if references.any?
      description
    end
    column to: :staff_only_comments do
      source_record.assessment_question.staff_comments
    end
    column to: :maximum_grade do
      source_record.assessment_question.max_grade.to_i
    end
    column to: :weight do
      source_record.assessment_question.question_assessments.first.position || 0
    end
    column to: :title do
      source_record.assessment_question.title
    end
    column to: :language_id do
      # V1: 1 => python3.3, 2 => python3.4, 3 => python2.7, 4 => python3.5
      # V2: 1 => JavaScript, 2 => Python 2.7, 3=>Python 3.4, 4=>Python 3.5, 5=>Python 3.6, 6=>C/C++
      case source_record.language_id
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
    column to: :memory_limit do
      if source_record.memory_limit
        # 22 - 28 is minimal memory required from manual tests, use 30 for safe.
        source_record.memory_limit + 30
      else
        nil
      end
    end
    column to: :time_limit do
      if source_record.time_limit && source_record.time_limit <= 30 && source_record.time_limit > 0
        source_record.time_limit
      else
        nil
      end
    end
    column to: :attempt_limit do
      source_record.assessment_question.attempt_limit
    end
    column to: :creator_id do
      result = V1::Source::User.transform(source_record.assessment_question.creator_id)
      self.updater_id = result
      result
    end
    column :updated_at
    column :created_at

    skip_saving_unless_valid
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