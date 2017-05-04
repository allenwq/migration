class V1 < DatabaseTransform::Schema
  Dir[File.dirname(__FILE__) + '/tables/*.rb'].each {|file| require file }
  require_relative 'models/base'
  Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
  Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
  Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each { |file| require file }

  $url_mapper = UrlHashMapper.new

  around_job do |&job|
    ActiveRecord::Base.remove_connection
    Source::Base.remove_connection
    ActiveRecord::Base.establish_connection
    Source::Base.establish_connection :v1
    ActsAsTenant.current_tenant = Instance.default
    User.stamper = User.system

    job.call

    ActiveRecord::Base.remove_connection
    Source::Base.remove_connection
  end

  thread ENV['thread'] || 4

  @course_id = ENV['course'].to_i
  @instance = ENV['instance']
  course_ids = Array(@course_id)

  unless ENV['course']
    puts 'Usage: rake db:transform[v1] course=xxx_id [instance=host_name thread=number fix_id=T/(F) skip_user=(T)/F reset_redis=(T)/F]'
    exit
  end

  dynamic_id = (ENV['fix_id'] || '').downcase == 'f'
  skip_user = (ENV['skip_user'] || '').downcase == 't'
  puts "Migrate course #{course_ids.join(', ')} ..."

  transform_users unless skip_user
  transform_courses(course_ids, !dynamic_id)
  transform_course_users(course_ids)

  transform_achievements(course_ids)
  transform_course_user_achievements(course_ids)

  transform_announcements(course_ids)
  transform_levels(course_ids)
  transform_manual_exp(course_ids)
  transform_lesson_plans(course_ids)

  transform_forums(course_ids)
  transform_forum_topics(course_ids)
  transform_forum_topic_views(course_ids)
  transform_forum_posts(course_ids)
  transform_forum_post_votes(course_ids)

  transform_assessment_tabs(course_ids)
  transform_assessments(course_ids)
  transform_assessment_mcq_questions(course_ids)
  transform_assessment_mcq_options(course_ids)
  transform_assessment_programming_questions(course_ids)
  transform_assessment_trq_questions(course_ids)

  transform_assessment_submissions(course_ids)
  transform_assessment_mcq_answers(course_ids)
  transform_assessment_mcq_answer_options(course_ids)
  transform_assessment_trq_answers(course_ids)
  transform_assessment_programming_answers(course_ids)
  transform_assessment_comments(course_ids)

  transform_assessment_skills(course_ids)

  transform_conditions(course_ids)
  transform_materials(course_ids)

  transform_surveys(course_ids)
  transform_survey_sections(course_ids)
  transform_survey_questions(course_ids)
  transform_survey_question_options(course_ids)

  after_transform do
    ensure_db_connection
    merge_annotation_topics(course_ids)

    instance = Instance.find_by(host: @instance)
    # Need to be default because we want to find the course in the default instance
    ActsAsTenant.current_tenant = Instance.default
    course_ids.each do |src_course_id|
      next unless instance

      dst_course = Course.find(Source::Course.transform(src_course_id))
      move_course_to_instance(dst_course, instance)
    end
  end

  class << self
    private

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
      puts "Moving course #{course.id} to #{instance.host} ..."

      # Move users belongs to courses in the instance to the instance.
      user_ids_to_move = course.users.select(:id)
      InstanceUser.where(user_id: user_ids_to_move).each do |instance_user|
        instance_user.update_column(:instance_id, instance.id)
      end

      course.update_column(:instance_id, instance.id)
    end

    # There are annotations of same file and line, this is to merge them into one.
    def merge_annotation_topics(course_ids)
      puts "Merging annotation topics for course #{course_ids.join(', ')}"

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
end
