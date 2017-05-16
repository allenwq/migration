class BaseTable
  def initialize(course_ids = [])
    @course_ids = course_ids
  end

  def migrate(old, new, &block)
    DSL.new(old, new, &block).eval
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

  def skip_save_unless_valid
    @new.save validate: false, if: proc {
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
