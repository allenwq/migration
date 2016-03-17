module CoursemologyV1::Source
  def_model 'tag_groups', 'tags'

  def_model 'taggable_tags' do
    scope :within_courses, ->(course_ids) do
      course_ids = Array(course_ids)
      joins('INNER JOIN tags ON tags.id = tag_id INNER JOIN tag_groups ON tags.tag_group_id = tag_groups.id').
        where("tag_groups.course_id IN (#{course_ids.join(' ')})")
    end
  end
end
