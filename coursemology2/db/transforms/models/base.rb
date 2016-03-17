module CoursemologyV1::Source
  class Base < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :coursemology_v1

    extend DatabaseTransform::SchemaTableRecordMapping
  end

  # Define models by their table names
  # table name `user_courses` will define a model UserCourse
  def self.def_model(*args, &block)
    args.each do |table|
      class_name = table.singularize.camelize
      const_set class_name, (Class.new(Base) do |klass|
        klass.table_name = table
        klass.default_scope do
          if klass.column_names.include?('deleted_at')
            where(deleted_at: nil)
          else
            all
          end
        end
        # Default within_courses implementation, works for all models that have a course_id.
        klass.scope :within_courses, ->(course_ids=[]) do
          where(course_id: Array(course_ids))
        end

        klass.class_exec(&block) if block
      end)
    end
  end

  def_model 'user_courses', 'announcements', 'achievements', 'levels'
end
