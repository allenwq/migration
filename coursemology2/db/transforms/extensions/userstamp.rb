ActiveRecord::Userstamp::Stampable.module_eval do
  # Do not set updater when it's present
  def set_updater_attribute_with_migration
    attribute = ActiveRecord::Userstamp.config.updater_attribute
    return if attribute.nil? || !has_attribute?(attribute)

    return if send(attribute).present?

    set_updater_attribute_without_migration
  end
  alias_method_chain :set_updater_attribute, :migration
end
