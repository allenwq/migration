module V1
  class BaseModel < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :v1

    def primary_key_value
      if self.class.respond_to?(:primary_keys) && self.class.primary_keys
        self.class.primary_keys.map { |primary_key| self.send primary_key }.join(',')
      elsif self.class.respond_to?(:primary_key) && self.class.primary_key
        self.send self.class.primary_key
      else
        self.id
      end
    end
  end

  # Define models by their table names
  # table name `user_courses` will define a model UserCourse
  def self.def_model(*args, &block)
    args.each do |table|
      class_name = table.singularize.camelize
      const_set class_name, (Class.new(BaseModel) do |klass|
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

        # Convert SG time to UTC time
        klass.columns.select { |c| c.type == :datetime }.each do |col|
          name = col.name
          define_method(name) do
            val = read_attribute(name)
            val -= 8.hours if val
            val
          end
        end

        # klass.extend(RecordMap)
        klass.class_exec(&block) if block
      end)
    end
  end
end
