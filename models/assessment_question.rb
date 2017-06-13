module V1
  def_model 'assessment_questions' do
    has_many :question_assessments, inverse_of: nil, foreign_key: 'question_id'
    has_many :assessments, through: :question_assessments, inverse_of: nil
    belongs_to :as_question, polymorphic: true, inverse_of: nil

    # Takes in general question id and return the v2 general question id
    def self.get_target_id(store, src_id)
      src_question = find(src_id)
      src_specific_question = src_question.as_question
      dst_specific_question_id = store.get(src_specific_question.class.table_name, src_specific_question.id)

      type = nil

      case src_specific_question.class.name.demodulize
      when AssessmentMcqQuestion.name.demodulize
        type = ::Course::Assessment::Question::MultipleResponse.name
      when AssessmentGeneralQuestion.name.demodulize
        type = ::Course::Assessment::Question::TextResponse.name
      when AssessmentCodingQuestion.name.demodulize
        type = ::Course::Assessment::Question::Programming.name
      when AssessmentScribingQuestion.name.demodulize
        type = ::Course::Assessment::Question::Scribing.name
      end

      ::Course::Assessment::Question.find_by(actable_type: type, actable_id:
        dst_specific_question_id).try(:id)
    end
  end

  def_model 'question_assessments' do
    belongs_to :assessment, inverse_of: nil
    belongs_to :question, class_name: 'AssessmentQuestion', inverse_of: nil
  end
end
