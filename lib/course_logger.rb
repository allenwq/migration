class CourseLogger

  def initialize(course_id)
    @course_id = course_id
  end

  def log(msg)
    open("log/course_#{@course_id}.log", 'a') do |f|
      f.puts "#{Time.now.iso8601(3)} #{msg}"
    end
  end

  def error(e)
    open("log/course_#{@course_id}.error", 'a') do |f|
      f.puts "#{Time.now.iso8601(3)} #{e.message}"
      f.puts e.backtrace
    end
  end
end
