TYPE_MAPPING = {
  'Assessment::McqQuestion' => V1::Source::AssessmentMcqQuestion.name,
  'Assessment::CodingQuestion' => V1::Source::AssessmentCodingQuestion.name,
  'Assessment::GeneralQuestion' => V1::Source::AssessmentGeneralQuestion.name,
  'Assessment::McqAnswer' => V1::Source::AssessmentMcqAnswer.name,
  'Assessment::CodingAnswer' => V1::Source::AssessmentCodingAnswer.name,
  'Assessment::GeneralAnswer' => V1::Source::AssessmentGeneralAnswer.name,
  'Achievement' => V1::Source::Achievement.name,
  'Level' => V1::Source::Level.name,
  'Assessment' => V1::Source::Assessment.name,
  'AsmReq' => V1::Source::AsmReq.name,
  'Material' => V1::Source::Material.name
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
