module V1
  def_model 'pending_actions' do
    belongs_to :user_course, class_name: 'UserCourse', inverse_of: nil

    def target_item_id(store)
      target_item(store).try(:id)
    end

    def target_item(store)
      @item ||= begin
        target = nil
        case item_type
        when 'Assessment'
          target_assessment = store.get(Assessment.table_name, item_id)
          target = ::Course::LessonPlan::Item.find_by(actable_type: 'Course::Assessment', actable_id: target_assessment) if target_assessment
        when 'Survey'
          target_survey = store.get(Survey.table_name, item_id)
          target = ::Course::LessonPlan::Item.find_by(actable_type: 'Course::Survey', actable_id: target_survey) if target_survey
        end

        target
      end
    end

    def target_workflow_state(store)
      # ["not_started", "in_progress", "completed"]
      # V1 pending action don't differentiate the states, it will find the submission and check submission state instead.
      state = 'not_started'

      if is_done
        state = 'completed'
      elsif submission = target_submission(store) && submission.attempting?
        state = 'in_progress'
      end

      state
    end

    private

    def target_submission(store)
      @submission ||= begin
        target_course_user_id = store.get(UserCourse.table_name, user_course_id)
        if target_course_user_id && item = target_item(store)
          submissions = nil
          submissions = item.specific.submissions if item.specific.is_a?(::Course::Assessment)
          submissions = item.specific.responses if item.specific.is_a?(::Course::Survey)
          submissions.joins { experience_points_record }.where { experience_points_record.course_user_id == my { target_course_user_id } }.first
        end
      end
    end
  end
end
