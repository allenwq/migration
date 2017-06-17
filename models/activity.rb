module V1
  def_model 'activities' do
    def target_actor_id(store)
      target_course_user = store.get(UserCourse.table_name, actor_course_id)
      CourseUser.find_by(id: target_course_user)&.user_id
    end

    def target_object(store)
      # Possible source object types: ["Achievement", "Assessment", "Level", "ForumPost", "ForumTopic"]
      # Possible target types: ["Course::Assessment", "Course::Forum::Topic", "Course::Discussion::Post",
      # "Course::Level", "Course::Achievement", "Course::Announcement", "Course::Assessment::Submission", "Course::Video"]
      target_type = case obj_type
                    when 'Achievement'
                      ::Course::Achievement.name
                    when 'Assessment'
                      ::Course::Assessment.name
                    when 'Level'
                      ::Course::Level.name
                    when 'ForumPost'
                      ::Course::Discussion::Post.name
                    when 'ForumTopic'
                      ::Course::Forum::Topic.name
                    end

      target_id = store.get("V1::#{obj_type}".constantize.table_name, obj_id)

      [target_type, target_id]
    end

    def target_notifier_and_event
      # Possible source combinations:
      # {"Achievement"=>[[4, "earned"]]},
      # {"Assessment"=>[[1, "attempted"], [7, "started"]]},
      # {"Level"=>[[4, "earned"], [8, "reached"]]},
      # {"ForumPost"=>[[6, "replied to"], [11, "voted on"]]},
      # {"ForumTopic"=>[[9, "created Forum topic"], [10, "asked"]]}

      # Possible target combinations
      # ["Course::AssessmentNotifier", "attempted"],
      # ["Course::Forum::TopicNotifier", "created"],
      # ["Course::Forum::PostNotifier", "replied"],
      # ["Course::LevelNotifier", "reached"],
      # ["Course::AchievementNotifier", "gained"],
      # ["Course::AnnouncementNotifier", "new"],
      # ["Course::AssessmentNotifier", "submitted"],
      # ["Course::Assessment::Answer::CommentNotifier", "annotated"],
      # ["Course::Assessment::Answer::CommentNotifier", "replied"],
      # ["Course::VideoNotifier", "attempted"],
      # ["Course::VideoNotifier", "opening"],
      # ["Course::Assessment::SubmissionQuestion::CommentNotifier", "replied"]
      case [obj_type, action_id]
      when ['Achievement', 4]
        ['Course::AchievementNotifier', 'gained']
      when ['Assessment', 1], ['Assessment', 7]
        ['Course::AssessmentNotifier', 'attempted']
      when ['Level', 4], ['Level', 8]
        ['Course::LevelNotifier', 'reached']
      when ['ForumPost', 6]
        ['Course::Forum::PostNotifier', 'replied']
      when ['ForumTopic', 9], ['ForumTopic', 10]
        ['Course::Forum::TopicNotifier', 'created']
      when ['ForumPost', 11]
        ['Course::Forum::PostNotifier', 'voted']
      else
        raise "Unexpected type: #{obj_type} #{action_id}"
      end
    end
  end
end

