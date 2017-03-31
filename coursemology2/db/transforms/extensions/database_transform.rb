class << DatabaseTransform::Schema
  def generate_model_with_defined_models(within, table_name)
    class_name = table_name.to_s.singularize.camelize

    if within.const_defined?(class_name)
      within.const_get(class_name)
    else
      generate_model_without_defined_models(within, table_name)
    end
  end
  alias_method_chain :generate_model, :defined_models
end

DatabaseTransform::SchemaTable.class_eval do
  def run_transform_with_persistence(*args)
    @source.reset_transform
    run_transform_without_persistence(*args)
  end
  alias_method_chain :run_transform, :persistence

  # Convert SG time to UTC time globally
  def assign_record_field_with_timezone_conversion!(old, new, column, new_value)
    if new_value.is_a?(Time)
      new_value -= 8.hours
    end
    assign_record_field_without_timezone_conversion!(old, new, column, new_value)
  end
  alias_method_chain :assign_record_field!, :timezone_conversion

  # Helper method.
  # Skip the invalid record and log errors.
  def skip_saving_unless_valid(&block)
    save validate: false, if: proc {
      # Use block for validation if given
      if block_given? && instance_exec(&block)
         true
      elsif !block_given? && valid?
        true
      else
        puts "Invalid #{source_record.class} #{source_record.primary_key_value}:"\
        " #{errors.full_messages.to_sentence}"
        false
      end
    }
  end
end

DatabaseTransform::SchemaTableRecordMapping.module_eval do
  def transform(old_primary_key)
    store.get(table_name, old_primary_key)
  end

  def transformed?(old_primary_key)
    store.has_key?(table_name, old_primary_key)
  end

  def memoize_transform(old_primary_key, new_key)
    store.set(table_name, old_primary_key, new_key)
  end

  def reset_transform
    store.reset_table(table_name)
  end

  def store
    @store ||= RedisStore.new
  end
end
