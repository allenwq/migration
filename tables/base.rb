class BaseTable
  attr_reader :store, :course_ids

  def initialize(store, course_ids = [])
    @store = store
    @course_ids = Array(course_ids)
  end

  def migrate(old, new, &block)
    DSL.new(old, new, &block).eval
  end

  def self.table_name(table_name)
    @table_name = table_name
  end

  def self.scope(&block)
    @scope = block
  end

  def model
    name = self.class.instance_variable_get(:@table_name)
    raise "Table name not defined: #{self.class.name}" unless name
    @model ||= "V1::#{name.singularize.camelize}".constantize
  end

  def run
    time = timer do
      table = self.class.instance_variable_get(:@table_name)
      Logger.log("Migrate #{table}...")

      scope = self.class.instance_variable_get(:@scope)
      model.instance_exec(course_ids, &scope).find_in_batches do |batch|
        migrate_batch(batch)
      end
    end

    Logger.log("finished in #{time.round(1)}s")
  end

  # Calculate the time of the action
  def timer
    start = Time.now
    yield if block_given?

    Time.now - start
  end
end

class DSL
  attr_reader :old, :new

  def initialize(old, new, &block)
    @old = old
    @new = new
    @block = block
    @caller = block.binding.eval 'self'

    extract_instance_variables_from(@caller)
  end

  def eval
    instance_exec(&@block)
  end

  def column(col)
    if col.is_a?(Hash)
      raise 'Invalid options' if col.keys.size > 1
      key = col.keys[0]
      new.send("#{col[key]}=", old.send(key))
    elsif col.is_a?(Symbol) && !block_given?
      new.send("#{col}=", old.send(col))
    elsif block_given?
      new.send("#{col}=", yield)
    else
      raise 'Unknown action'
    end
  end

  def skip_saving_unless_valid
    # Use block for validation if given
    if block_given? && new.instance_exec(&block)
      new.save(validate: false)
    elsif !block_given? && new.valid?
      new.save(validate: false)
    else
      puts "Invalid #{old.class} #{old.primary_key_value}: #{new.errors.full_messages.to_sentence}"
    end
  end

  def method_missing(method, *args)
    if @caller.respond_to?(method)
      @caller.send(method, *args)
    else
      super
    end
  end

  private

  def extract_instance_variables_from(caller)
    caller.instance_variables.each do |name|
      value = caller.instance_variable_get(name)
      instance_variable_set(name, value) unless instance_variable_defined?(name)
    end
  end
end
