# Disable autosave
# `accepts_nested_attributes_for` enables autosave, and as everyone knows
# autosave has tons of issues =_=
# In the case of migration, enable autosave leads to double save which causes the timestamp
# being overwritten.

# Below are the results of
# `puts "::#{self.name}._reflect_on_association('#{association_name}').options.delete(:autosave)"`
# in activerecord-4.2.8/lib/active_record/nested_attributes.rb#accepts_nested_attributes_for

::Course::Group._reflect_on_association('group_users').options.delete(:autosave)
::Course::Discussion::Topic._reflect_on_association('posts').options.delete(:autosave)
::Course::Assessment::Answer._reflect_on_association('actable').options.delete(:autosave)
::Course::Assessment::Question::MultipleResponse._reflect_on_association('options').options.delete(:autosave)
::Course::Assessment::Answer::Programming._reflect_on_association('files').options.delete(:autosave)
::Course::Assessment::Submission._reflect_on_association('answers').options.delete(:autosave)
::Course::Assessment::Question::TextResponse._reflect_on_association('solutions').options.delete(:autosave)
::Course::Assessment::Category._reflect_on_association('tabs').options.delete(:autosave)
::Course::Survey::Response._reflect_on_association('answers').options.delete(:autosave)
::Course._reflect_on_association('invitations').options.delete(:autosave)
::Course._reflect_on_association('assessment_categories').options.delete(:autosave)
::User._reflect_on_association('emails').options.delete(:autosave)
::Course::Survey::Answer._reflect_on_association('options').options.delete(:autosave)
::Course::Survey::Question._reflect_on_association('options').options.delete(:autosave)
