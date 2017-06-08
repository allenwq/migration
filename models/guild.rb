module V1
  def_model 'guilds'

  def_model 'guild_users' do
    belongs_to :guild, inverse_of: nil

    scope :within_courses, ->(course_ids) do
      joins(:guild).
        where(guild: { course_id: Array(course_ids) })
    end
  end
end
