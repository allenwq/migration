module V1
  def_model 'assessment_questions' do
    has_many :question_assessments, inverse_of: nil, foreign_key: 'question_id'
    has_many :assessments, through: :question_assessments, inverse_of: nil
    belongs_to :as_question, polymorphic: true, inverse_of: nil
  end

  def_model 'question_assessments' do
    belongs_to :assessment, inverse_of: nil
    belongs_to :question, class_name: 'AssessmentQuestion', inverse_of: nil
  end
end
