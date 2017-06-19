module V1
  def_model 'tutorial_groups' do
  end

  ::Course::Group.class_eval do
    def set_defaults
    end
  end

  ::Course::GroupUser.class_eval do
    def course_user_and_group_in_same_course
      return if group.nil? || course_user.nil? || group.course == course_user.course
      errors.add(:course_user, :not_enrolled)
    end
  end
end
