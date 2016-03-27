module CoursemologyV1::Source
  def_model 'tabs'

  def_model 'assessments' do
    has_many :file_uploads, as: :owner, inverse_of: nil
  end

  ::Course::Assessment.class_eval do
    # Disable draft validation
    def draft_status
    end
  end
end
