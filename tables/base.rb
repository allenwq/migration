class BaseTable
  attr_reader :store, :logger, :course_ids, :concurrency, :records_processed

  def initialize(store, logger, course_ids = [], concurrency = 1)
    @store = store
    @course_ids = Array(course_ids)
    @logger = logger
    @concurrency = concurrency
    @records_processed = 0

    setup_tenant_and_stamper

    if concurrency > 1
      @worker = ProcessPool.new(concurrency)

      @worker.around_job do |&job|
        setup_tenant_and_stamper
        job.call
      end
    end
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
      logger.log("Migrate #{table}...")

      if process_in_batches?
        stabilize_source_connection if parallel?
        source_records.find_in_batches do |batch|
          process_batch(batch)
          stabilize_source_connection if parallel?
        end
      else
        process_batch(source_records)
      end

      @worker.wait if @worker
    end

    verify_count!

    logger.log("Finished in #{time.round(1)}s")
  end

  # Rollback the changes in Redis in case of failure
  # Only required for concurrency environment
  def rollback
    source_records.pluck(:id).each do |id|
      store.del(model.table_name, id)
    end
  end

  def source_records
    model.instance_exec(course_ids, &model_scope)
  end

  def setup_tenant_and_stamper
    User.stamper = User.system
    ActsAsTenant.current_tenant = Instance.default
  end

  def process_in_batches?
    source_records.respond_to?(:find_in_batches)
  end

  protected

  def ensure_db_connection
    conn = ActiveRecord::Base.connection
    conn_v1 = model.connection
    begin
      try ||= 3
      conn.reconnect!
      conn_v1.reconnect!
    rescue
      try -= 1
      # There is a issue where connection closed unexpectedly, need retry
      retry if try > 0
    end
  end

  def stabilize_source_connection
    begin
      try ||= 3
      source_records.first
    rescue
      try -= 1
      retry if try > 0
    end
  end

  private

  def model_scope
    self.class.instance_variable_get(:@scope)
  end

  def process_batch(batch)
    @records_processed += batch.size

    if !parallel?
      migrate_batch(batch)
    else
      # Use worker to split jobs if concurrency is great than 1
      @worker.schedule do
        migrate_batch(batch)
      end
    end
  end

  # Calculate the time of the action
  def timer
    start = Time.now
    yield if block_given?

    Time.now - start
  end

  def parallel?
    concurrency > 1
  end

  def verify_count!
    count = source_records.count
    if count != records_processed
      raise "Records processed(#{records_processed}) and total number of records(#{count}) does not match"
    end
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

  def skip_saving_unless_valid(&block)
    # Use block for validation if given
    if block_given? && new.instance_exec(&block)
      new.save(validate: false)
    elsif !block_given? && new.valid?
      new.save(validate: false)
    else
      logger.log "Invalid #{old.class} #{old.primary_key_value}: #{new.errors.full_messages.to_sentence}"
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
