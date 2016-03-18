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
    @source.reset_mapping
    run_transform_without_persistence(*args)
    @source.persist_mapping
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
  def skip_saving_unless_valid
    save validate: false, if: proc {
      if valid?
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
    mapping[old_primary_key.to_s]
  end

  def transformed?(old_primary_key)
    mapping.has_key?(old_primary_key.to_s)
  end

  def memoize_transform(old_primary_key, result)
    mapping[old_primary_key.to_s] = result.id
  end

  def mapping
    @mapping ||= store.get(store_key)
  end

  def reset_mapping
    @mapping = {}
  end

  def persist_mapping
    store.set(store_key, mapping)
  end

  private

  def store_key
    'data_migration_v2_' + self.table_name
  end

  def store
    @store ||= YAMLStore.new
  end
end

class YAMLStore
  STORE_PATH = Rails.root.join('tmp/saved_mappings')

  def initialize
    FileUtils.mkdir(STORE_PATH) unless File.exist?(STORE_PATH)
  end

  def get(key)
    path = File.join(STORE_PATH, "#{key}.yaml")
    if File.exist?(path)
      YAML.load(File.open(path))
    else
      {}
    end
  end

  def set(key, data)
    path = File.join(STORE_PATH, "#{key}.yaml")
    file = File.open(path, 'w')
    file.write data.to_yaml
    file.close
  end
end
