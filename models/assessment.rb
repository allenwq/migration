module V1
  def_model 'tabs'

  def_model 'assessment_missions'
  def_model 'assessment_trainings'

  def_model 'assessments' do
    has_many :file_uploads, as: :owner, inverse_of: nil
    belongs_to :as_assessment, polymorphic: true, inverse_of: nil

    def specific
      as_assessment
    end
  end

  ::Course::Assessment.class_eval do
    # Disable draft validation
    raise 'Method removed validate_prescence_of_questions' unless private_instance_methods(false).include?(:validate_presence_of_questions)
    def validate_presence_of_questions
    end
  end
end
