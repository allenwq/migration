TYPE_MAPPING = {
  'Assessment::McqQuestion' => CoursemologyV1::Source::AssessmentMcqQuestion.name,
  'Assessment::CodingQuestion' => CoursemologyV1::Source::AssessmentCodingQuestion.name,
  'Assessment::GeneralQuestion' => CoursemologyV1::Source::AssessmentGeneralQuestion.name,
  'Assessment::McqAnswer' => CoursemologyV1::Source::AssessmentMcqAnswer.name,
  'Assessment::CodingAnswer' => CoursemologyV1::Source::AssessmentCodingAnswer.name,
  'Achievement' => CoursemologyV1::Source::Achievement.name,
  'Level' => CoursemologyV1::Source::Level.name,
  'Assessment' => CoursemologyV1::Source::Assessment.name,
  'AsmReq' => CoursemologyV1::Source::AsmReq.name
}

module ActiveRecord
  module Associations
    class BelongsToPolymorphicAssociation < BelongsToAssociation #:nodoc:
      def klass
        type = owner[reflection.foreign_type]
        if TYPE_MAPPING[type]
          type = TYPE_MAPPING[type]
        end
        type.presence && type.constantize
      end
    end

    AssociationRelation.class_eval do
      def bind_values_with_type_conversion
        bind_values_without_type_conversion.each do |pair|
          if pair[1] && TYPE_MAPPING.key(pair[1])
            pair[1] = TYPE_MAPPING.key(pair[1])
          end
        end
      end

      alias_method_chain :bind_values, :type_conversion
    end
  end
end

module Arel
  TreeManager.class_eval do
    def bind_values_with_type_conversion
      bind_values_without_type_conversion.each do |pair|
        if pair[1] && TYPE_MAPPING.key(pair[1])
          pair[1] = TYPE_MAPPING.key(pair[1])
        end
      end
    end

    alias_method_chain :bind_values, :type_conversion
  end
end
