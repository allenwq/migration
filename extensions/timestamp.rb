# There's a bug somethere which does not allow the overriding of timestamps
ActiveRecord::Base.record_timestamps = false
::Attachment.record_timestamps = true
::AttachmentReference.record_timestamps = true

[::InstanceUser, ::User::Identity].each do |klass|
  klass.record_timestamps = true
end
