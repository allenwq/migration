class CourseMigrator
  def initialize(course_id, concurrency:, fix_id: true)
    @course_id = course_id
    @concurrency = concurrency
    @fix_id = fix_id
  end

  def start
    new_courses = CourseTable.new([@course_id], fix_id: @fix_id).run
    puts "Course #{@course_id} is migrated to #{new_courses[0]}"
  end
end
