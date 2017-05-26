module V1
  def_model 'tag_groups', 'tags'

  def_model 'taggable_tags' do
    # There's only one taggable type, so all taggable_id points to question
    belongs_to :question, class_name: 'AssessmentQuestion', foreign_key: :taggable_id, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      course_ids = Array(course_ids)
      # filter out tags with deleted assessments, there are assessments with deleted_at set and questions of them are not migrated.
      joins(question: { question_assessments: :assessment }).
      joins('INNER JOIN tags ON tags.id = tag_id INNER JOIN tag_groups ON tags.tag_group_id = tag_groups.id').
        where("tag_groups.course_id IN (#{course_ids.join(', ')})")
    end
  end
end
