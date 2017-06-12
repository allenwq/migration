require_relative 'models/base'
require_relative 'tables/base'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/migrators/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/tables/*.rb'].each { |file| require file }

def timer
  start = Time.now
  yield if block_given?

  Time.now - start
end

begin
  pool = ProcessPool.new(4)
ensure
  pool.terminate!
end

$url_mapper = UrlHashMapper.new
unless defined? Rails::Console
  # UserMigrator.new.start
  [21, 56, 83, 122, 123, 120, 139, 146, 149, 150, 136, 196, 224, 232, 214, 262, 253, 343, 362, 360,
  361, 320, 342, 382, 383, 451, 315, 480, 505, 517, 538, 518, 541, 276, 555, 556, 546, 564, 579, 580,
  585, 586, 588, 497, 596, 602].reverse.each do |id|
    pool.schedule do
      logger = Logger.new(id)
      begin
        puts "Course #{id} migration started"
        time = timer do
          CourseMigrator.new(id, logger, concurrency: 1, fix_id: true).start
        end.round(1)
        logger.log "Migration finished in #{time} s"
        puts "Course #{id} migration finished in #{time} s"
      rescue Exception => e
        logger.error e
        puts "Course #{id} migration errored, check logs for details"
      end
    end
  end

  pool.wait
end
