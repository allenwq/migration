# This file is used to disable all global callbacks
::Course::ReminderConcern.module_eval do
  raise 'Method removed' unless private_instance_methods(false).include?(:setup_opening_reminders)
  def setup_opening_reminders
  end

  raise 'Method removed' unless private_instance_methods(false).include?(:setup_closing_reminders)
  def setup_closing_reminders
  end
end

# Don't create TODOs in callbacks
::Course::LessonPlan::ItemTodoConcern.module_eval do
  raise 'Method removed' unless public_instance_methods(false).include?(:create_todos)
  def create_todos
  end

  raise 'Method removed' unless public_instance_methods(false).include?(:has_todo?)
  def has_todo?
    false
  end
end
