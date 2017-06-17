class CourseLogger

  def initialize(course_id)
    @course_id = course_id
  end

  def log(msg)
    open("log/course_#{@course_id}.log", 'a') do |f|
      f.puts "#{timestamp} #{msg}"
    end
  end

  def error(e)

    open("log/course_#{@course_id}.error", 'a') do |f|
      f.puts "#{timestamp} #{e.message}"
      f.puts e.backtrace
    end
  end

  def timestamp
    Time.now.in_time_zone('Singapore').strftime('%F %T')
  end
end
