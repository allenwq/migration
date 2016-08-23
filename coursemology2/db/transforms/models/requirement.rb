module CoursemologyV1::Source
  def_model 'asm_reqs' do
    belongs_to :asm, polymorphic: true
  end

  def_model 'requirements' do
    # Currently obj is only achievement
    belongs_to :obj, polymorphic: true
    belongs_to :req, polymorphic: true

    scope :within_courses, ->(course_ids) do
      course_ids = Array(course_ids)
      # joins(:obj).where(obj: { course_id: course_ids })
      joins('INNER JOIN achievements ON requirements.obj_id = achievements.id').
        where("achievements.course_id IN (#{course_ids.join(', ')})").
        includes(:obj, :req)
    end

    def transform_actable
      case req_type
      when 'Achievement'
        ::Course::Condition::Achievement.new(achievement_id: Achievement.transform(req_id))
      when 'Level'
        dst_lvl_id = Level.transform(req_id)
        lvl_number = 0
        lvl_number = ::Course::Level.find(dst_lvl_id).level_number if dst_lvl_id
        ::Course::Condition::Level.new(minimum_level: lvl_number)
      when 'AsmReq'
        dst_assessment_id = Assessment.transform(req.asm_id)
        percent = req.min_grade.to_f # min_grade is a percent, not grade.
        ::Course::Condition::Assessment.new(assessment_id: dst_assessment_id,
                                            minimum_grade_percentage: percent)
      end
    end
  end

  def_model 'assessment_dependency' do
    belongs_to :assessment, foreign_key: 'id', inverse_of: nil

    scope :within_courses, ->(course_ids) do
      course_ids = Array(course_ids)
      joins(:assessment).where(assessment: { course_id: course_ids })
    end
  end
end
