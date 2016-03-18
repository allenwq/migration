module CoursemologyV1::Source
  def_model 'users'

  ::User.class_eval do
    # Do not create read marks, for performance.
    def setup_new_reader
    end
  end
end
