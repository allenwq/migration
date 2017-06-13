require_relative 'models/base'
require_relative 'tables/base'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/migrators/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/tables/*.rb'].each { |file| require file }

begin
  pool = ProcessPool.new(4)
  course_ids = []

  $url_mapper = UrlHashMapper.new
  unless defined? Rails::Console
    # UserMigrator.new.start
    course_ids.each do |id|
      pool.schedule do
        logger = CourseLogger.new(id)
        CourseMigrator.new(id, logger, concurrency: 1, fix_id: true).start
      end
    end

    pool.wait
  end
ensure
  pool.terminate!
end
