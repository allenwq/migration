module CoursemologyV1::Source
  def_model 'tabs'

  def_model 'assessments' do
    has_many :file_uploads, as: :owner, inverse_of: nil
  end

  ::Course::Assessment.class_eval do
    # Disable draft validation
    raise 'Method removed validate_prescence_of_questions' unless private_instance_methods(false).include?(:validate_prescence_of_questions)
    def validate_prescence_of_questions
    end

    raise 'Method removed' unless private_instance_methods(false).include?(:validate_only_autograded_questions)
    # Skip autograde validation
    def validate_only_autograded_questions
    end
  end
end
