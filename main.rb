require_relative 'models/base'
require_relative 'tables/base'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/migrators/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/tables/*.rb'].each { |file| require file }

$url_mapper = UrlHashMapper.new

unless defined? Rails::Console
  UserMigrator.new.start
  CourseMigrator.new(362, concurrency: 4, fix_id: false).start
end
