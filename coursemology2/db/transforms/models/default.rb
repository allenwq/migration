module V1::Source
  def_model 'user_courses' do
    time_shift :last_active_time
  end

  def_model 'levels'
end
