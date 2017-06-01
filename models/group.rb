module V1
  def_model 'tutorial_groups' do
  end

  ::Course::Group.class_eval do
    def set_defaults
    end
  end
end
