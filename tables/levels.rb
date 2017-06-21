class LevelTable < BaseTable
  table_name 'levels'
  scope { |ids| within_courses(ids) }

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course::Level.new

      if old.exp_threshold == 0
        # No need to transform as there's already a default level
        new_course_id = store.get(V1::Course.table_name, old.course_id)
        new_lvl = ::Course::Level.find_by(course_id: new_course_id, experience_points_threshold: 0)

        if new_lvl
          new_lvl.update_columns(updated_at: old.updated_at, created_at: old.created_at)
          store.set(model.table_name, old.id, new_lvl.id)
          next
        end
      end

      migrate(old, new) do
        column :course_id do
          store.get(V1::Course.table_name, old.course_id)
        end
        column :exp_threshold => :experience_points_threshold
        column :updated_at
        column :created_at

        if new.course
          dup = new.course.levels.find_by(experience_points_threshold: old.exp_threshold)
          if dup
            # This is to handle duplicate levels in the source course
            store.set(model.table_name, old.id, dup.id)
            next
          end
        end

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end
end

# Schema
#
# V2:
# create_table "course_levels", force: :cascade do |t|
#   t.integer  "course_id",                   null: false, index: {name: "fk__course_levels_course_id"}, foreign_key: {references: "courses", name: "fk_course_levels_course_id", on_update: :no_action, on_delete: :no_action}
#   t.integer  "experience_points_threshold", null: false
#   t.datetime "created_at",                  null: false
#   t.datetime "updated_at",                  null: false
# end

# V1
# create_table "levels", :force => true do |t|
#   t.integer  "level"
#   t.integer  "exp_threshold"
#   t.integer  "course_id"
#   t.integer  "creator_id"
#   t.datetime "created_at",    :null => false
#   t.datetime "updated_at",    :null => false
# end