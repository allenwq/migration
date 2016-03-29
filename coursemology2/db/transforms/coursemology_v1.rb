class CoursemologyV1 < DatabaseTransform::Schema
  Dir[File.dirname(__FILE__) + '/tables/*.rb'].each {|file| require file }
  require_relative 'models/base'
  Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
  Dir[File.dirname(__FILE__) + '/lib/*.rb'].each { |file| require file }
  Dir[File.dirname(__FILE__) + '/extensions/*.rb'].each { |file| require file }

  ActsAsTenant.current_tenant = Instance.default
  User.stamper = User.system
  $url_mapper = UrlHashMapper.new

  course_ids = 362
  transform_users
  transform_courses(course_ids)
  transform_course_users(course_ids)
  transform_achievements(course_ids)
  transform_course_user_achievements(course_ids)
  transform_announcements(course_ids)
  transform_levels(course_ids)
  transform_manual_exp(course_ids)
  transform_lesson_plans(course_ids)
  transform_forums(course_ids)
  transform_forum_topics(course_ids)
  transform_forum_posts(course_ids)
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
  transform_assessment_skills(course_ids)
  transform_conditions(course_ids)
  transform_materials(course_ids)
end
