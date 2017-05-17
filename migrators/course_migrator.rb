class CourseMigrator
  attr_reader :course_id, :concurrency

  def initialize(course_id, concurrency:, fix_id: true)
    @course_id = course_id
    @concurrency = concurrency
    @fix_id = fix_id
  end

  def start
    store = CachedWriteStore.new
    new_courses = []
    ::Course.transaction do
      new_courses = CourseTable.new(store, [course_id], fix_id: @fix_id).run
      CourseUserTable.new(store, [course_id]).run
      AchievementTable.new(store, [course_id]).run
      AssessmentTabTable.new(store, [course_id]).run
      AssessmentTable.new(store, [course_id]).run
    end
    store.persist_to_redis

    Logger.log "Course #{@course_id} is migrated to #{new_courses[0]}"
  end
end
