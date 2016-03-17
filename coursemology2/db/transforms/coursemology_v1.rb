class CoursemologyV1 < DatabaseTransform::Schema
  Dir[File.dirname(__FILE__) + '/tables/*.rb'].each {|file| require file }
  require_relative 'models/base'
  Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }

  require_relative 'extensions/database_transform'
  require_relative 'extensions/type_mapping'

  ActsAsTenant.current_tenant = Instance.default
  User.stamper = User.system

  courses_ids = [97]

  transform_users
  transform_courses(courses_ids)
  transform_course_users(courses_ids)
  transform_achievements(courses_ids)
  transform_announcements(courses_ids)
  transform_levels(courses_ids)
  transform_lesson_plans(courses_ids)
  transform_forums(courses_ids)
  transform_forum_topics(courses_ids)
  transform_forum_posts(courses_ids)
  transform_assessment_tabs(courses_ids)
  transform_assessments(courses_ids)
  transform_assessment_mcq_questions(courses_ids)
  transform_assessment_mcq_options(courses_ids)
  transform_assessment_programming_questions(courses_ids)
  transform_assessment_trq_questions(courses_ids)
  transform_assessment_submissions(courses_ids)
  transform_assessment_mcq_answers(courses_ids)
  transform_assessment_mcq_answer_options(courses_ids)
  transform_assessment_trq_answers(courses_ids)
  transform_assessment_programming_answers(courses_ids)
  transform_assessment_skills(courses_ids)
end
