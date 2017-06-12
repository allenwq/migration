module V1
  def_model 'lesson_plan_milestones'

  def_model 'lesson_plan_entries' do
    # V1:
    # ENTRY_TYPES = [
    #   ['Lecture', 0],
    #   ['Recitation', 1],
    #   ['Tutorial', 2],
    #   ['Other', 3]
    # ]

    # V2:
    # enum event_type: { other: 0, lecture: 1, recitation: 2, tutorial: 3 }
    def transform_entry_type
      case entry_type
      when 0
        :lecture
      when 1
        :recitation
      when 2
        :tutorial
      else
        :other
      end
    end
  end

  def_model 'lesson_plan_resources' do
    belongs_to :lesson_plan_entry, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:lesson_plan_entry).where(lesson_plan_entry: { course_id: Array(course_ids) })
    end
  end
end
