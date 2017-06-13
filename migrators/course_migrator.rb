class CourseMigrator
  attr_reader :course_id, :logger, :concurrency, :store

  def initialize(course_id, logger, concurrency:, fix_id: true)
    @course_id = course_id
    @logger = logger
    @concurrency = concurrency
    @fix_id = fix_id
    @store = concurrency == 1 ? CachedWriteStore.new : RedisStore.new
  end

  def start
    puts "Course #{course_id} migration started"

    new_course_id = nil
    time = timer do
      new_course_id = migrate()
    end.round(1)

    logger.log "Course #{course_id} is migrated to #{new_course_id}" if new_course_id
    logger.log "Migration finished in #{time} s"
    puts "Course #{course_id} migration finished in #{time} s"
  rescue Exception => e
    logger.error e
    puts "Course #{course_id} migration errored, check logs for details"
  end

  private

  def timer
    start = Time.now
    yield if block_given?

    Time.now - start
  end

  def migrate
    if concurrency <= 1
      single_thread_migrate
    else
      parallel_migrate
    end
  end

  def single_thread_migrate
    logger.log "Start migrating course #{course_id} ..."
    new_course_id = nil

    ::Course.transaction do
      results = tables.map(&:run)
      new_course_id = results[0][0] if results[0]
    end
    store.persist_to_redis

    new_course_id
  end

  def parallel_migrate
    logger.log "Start migrating course #{course_id} using #{concurrency} processes..."
    new_course_id = nil

    begin
      started = []
      tables.each_with_index do |t, index|
        started << t
        ret = t.run
        # First table is the course table
        new_course_id = ret[0] if t.is_a?(CourseTable) && ret
      end
    rescue Exception => e
      logger.error e
      logger.log "Migration of #{course_id} failed, rolling back and deleting target course #{new_course_id}"

      if new_course_id
        ensure_db_connection
        ::Course.find(new_course_id).destroy

        new_course_id = nil
      end
      started.each(&:rollback)
    end

    new_course_id
  end

  def tables
    @tables ||= begin
      ts = []
      ts << CourseTable.new(store, logger, course_id, fix_id: @fix_id)

      ts += [
        CourseUserTable,
        AnnouncementTable,
        AchievementTable,
        LevelTable,
        ExpRecordTable,
        LessonPlanMilestoneTable,
        LessonPlanEventTable,

        ForumTable,
        ForumTopicTable,
        ForumTopicViewTable,
        ForumPostTable,
        ForumPostVoteTable,

        AssessmentTabTable,
        AssessmentTable,
        AssessmentMcqQuestionTable,
        AssessmentMcqOptionTable,
        AssessmentTrqQuestionTable,
        AssessmentTrqKeywordSolutionTable,
        AssessmentTrqExactMatchSolutionTable,
        AssessmentScribingQuestionTable,
        AssessmentProgrammingQuestionTable,

        AssessmentSubmissionTable,
        AssessmentMcqAnswerTable,
        AssessmentMcqAnswerOptionTable,
        AssessmentTrqAnswerTable,
        AssessmentScribingAnswerTable,
        AssessmentAnswerScribbleTable,
        AssessmentProgrammingAnswerTable,

        AssessmentSkillGroupTable,
        AssessmentSkillTable,
        AssessmentQuestionSkillTable,
        CommentTopicTable,
        AssessmentCommentTable,
        AssessmentAnnotationTable,

        ConditionTable,
        AssessmentConditionTable,

        MaterialFolderTable,
        MaterialTable,
        LessonPlanEventMaterialTable,

        SurveyTable,
        SurveySectionTable,
        SurveyQuestionTable,
        SurveyQuestionOptionTable,
        SurveyResponseTable,
        SurveyTextAnswerTable,
        SurveyMrqAnswerTable,

        LessonPlanTodoTable,
        ActivityTable,
        EnrolRequestTable,

        GroupTable,
        GroupUserTable,
        GuildTable,
        GuildUserTable,
        CourseUserInvitationTable,

        ForumSubscriptionTable,
        ForumTopicSubscriptionTable,
        CommentSubscriptionTable,
      ].map { |t| t.new(store, logger, course_id, concurrency) }

      ts
    end
  end

  # Useful for concurrency environment
  def ensure_db_connection
    conn = ActiveRecord::Base.connection
    begin
      try ||= 3
      conn.reconnect!
    rescue
      try -= 1
      # There is a issue where connection closed unexpectedly, need retry
      retry if try > 0
    end
  end

  def move_course_to_instance(course, instance)
    logger.log "Moving course #{course.id} to #{instance.host} ..."

    # Move users belongs to courses in the instance to the instance.
    user_ids_to_move = course.users.select(:id)
    InstanceUser.where(user_id: user_ids_to_move).each do |instance_user|
      instance_user.update_column(:instance_id, instance.id)
    end

    course.update_column(:instance_id, instance.id)
  end

  # There are annotations of same file and line, this is to merge them into one.
  def merge_annotation_topics(course_ids)
    logger.log "Merging annotation topics for course #{course_ids.join(', ')}"

    course_ids.each do |course_id|
      ids = Course::Assessment::Answer::ProgrammingFileAnnotation.joins(:discussion_topic).
        where("course_discussion_topics.course_id = #{course_id}").pluck(:id)
      duplicate_ids = Course::Assessment::Answer::ProgrammingFileAnnotation.where(id: ids).
        select([:line, :file_id]).group(:line, :file_id).having('count(*) > 1').to_a
      duplicate_ids.each do |attr|
        do_merge(attr.file_id, attr.line)
      end
    end
  end

  def do_merge(file_id, line)
    annotations = Course::Assessment::Answer::ProgrammingFileAnnotation.where(file_id: file_id, line: line)

    original = annotations[0]
    duplicated = annotations[1..-1]
    duplicated.each do |annotation|
      annotation.posts.each do |post|
        post.update_column(:topic_id, original.acting_as.id)
      end
      annotation.delete
    end
  end
end
