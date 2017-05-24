class CourseTable < BaseTable
  table_name 'courses'
  scope { |ids| where(id: ids) }

  def initialize(store, ids, options = {})
    super(store)
    @course_ids = Array(ids)
    @fix_id = options[:fix_id].nil? ? true : options[:fix_id]
  end

  def run
    super

    course_ids.map { |id| store.get(model.table_name, id) }
  end

  def migrate_batch(batch)
    batch.each do |old|
      new = ::Course.new

      migrate(old, new) do
        column :id do
          # Instance variable not accessible
          @fix_id ? old.id + 1000 : nil
        end

        column :creator_id do
          store.get(V1::User.table_name, old.creator_id)
        end
        column :title
        column :description
        column :is_publish => :published
        column :is_open => :enrollable

        column :assessment_categories do
          migrate_settings(old, new)
          build_assessment_categories(old, new)
        end

        column :start_at do
          old.start_at || old.created_at
        end
        column :end_at do
          old.end_at || Time.now
        end
        column :updated_at
        column :created_at

        logo_file = old.transform_logo
        if logo_file
          new.logo = logo_file
          logo_file.close unless logo_file.closed?
        end

        new.root_folder.created_at = old.root_folder.created_at || old.created_at
        new.root_folder.updated_at = old.root_folder.updated_at || old.created_at
        level = new.levels.first
        level.created_at = old.created_at
        level.updated_at = old.updated_at

        skip_saving_unless_valid
        store.set(model.table_name, old.id, new.id)
      end
    end
  end

  def build_assessment_categories(source, destination)
    if destination.assessment_categories.length == 0 || destination.assessment_categories.length > 1
      raise 'No category or more than 1 categories found'
    end

    default_category = destination.assessment_categories.first
    training_pref = source.training_pref

    default_category.assign_attributes(
      title: training_pref.name,
      weight: training_pref.pos,

      creator_id: store.get(V1::User.table_name, source.creator_id),
      updater_id: store.get(V1::User.table_name, source.creator_id),
      created_at: training_pref.created_at,
      updated_at: training_pref.updated_at
    )

    mission_pref = source.mission_pref
    mission_category = Course::Assessment::Category.new(
      title: mission_pref.name,
      weight: mission_pref.pos,

      creator_id: store.get(V1::User.table_name, source.creator_id),
      updater_id: store.get(V1::User.table_name, source.creator_id),
      created_at: mission_pref.created_at,
      updated_at: mission_pref.updated_at
    )

    [default_category, mission_category].each do |cat|
      cat.folder.created_at = cat.created_at
      cat.folder.updated_at = cat.updated_at

      tab = cat.tabs.first
      tab.created_at = cat.created_at
      tab.updated_at = cat.updated_at
    end

    [default_category, mission_category]
  end

  def migrate_settings(source, destination)
    mapping = {
      'announcements' => { sidebar_key: :announcements, # Key for sidebar settings
                           component_settings_key: :announcement, # Key for concrete component settings
                           component_key: :course_announcements_component, # Component index settings
                           default_name: 'Announcements'},
      'achievements' => { sidebar_key: :achievements,
                          component_settings_key: nil,
                          component_key: :course_achievements_component,
                          default_name: 'Achievements'},
      'leaderboard' => { sidebar_key: :leaderboard,
                         component_settings_key: :leaderboard,
                         component_key: :course_leaderboard_component,
                         default_name: 'Leaderboard'},
      'students' => { sidebar_key: :users,
                      component_settings_key: nil,
                      component_key: nil,
                      default_name: 'Students'},
      'lesson_plan' => { sidebar_key: :lesson_plan,
                         component_settings_key: nil,
                         component_key: :course_lesson_plan_component,
                         default_name: 'Lesson Plan'},
      'materials' => { sidebar_key: :materials,
                       component_settings_key: :material,
                       component_key: :course_materials_component,
                       default_name: 'Materials'},
      'forums' => { sidebar_key: :forums,
                    component_settings_key: :forum,
                    component_key: :course_forums_component,
                    default_name: 'Forums'}
    }
    source.course_navbar_preferences.each do |nav_pref|
      key = nav_pref.item
      next unless item_hash = mapping[key]

      # Sidebar order
      destination.settings(:sidebar, item_hash[:sidebar_key]).weight = nav_pref.pos

      if component_settings_key = item_hash[:component_settings_key]
        # Handle individual component settings here
        if nav_pref.name != item_hash[:default_name]
          destination.settings(component_settings_key).title = nav_pref.name
        end
      end

      if component_key = item_hash[:component_key]
        # Component enable/disable settings
        destination.settings(:components, component_key).enabled = nav_pref.is_enabled
      end
    end
  end
end


# V1:
# create_table "courses", :force => true do |t|
#   t.string   "title"
#   t.integer  "creator_id"
#   t.text     "description"
#   t.datetime "created_at",                             :null => false
#   t.datetime "updated_at",                             :null => false
#   t.string   "logo_url"
#   t.string   "banner_url"
#   t.time     "deleted_at"
#   t.boolean  "is_publish",          :default => false
#   t.boolean  "is_open",             :default => true
#   t.boolean  "is_active",           :default => true
#   t.datetime "start_at"
#   t.datetime "end_at"
#   t.boolean  "is_pending_deletion", :default => false
# end

# V2:
# create_table "courses", force: :cascade do |t|
#   t.integer  "instance_id",      :null=>false, :index=>{:name=>"fk__courses_instance_id"}, :foreign_key=>{:references=>"instances", :name=>"fk_courses_instance_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.string   "title",            :limit=>255, :null=>false
#   t.text     "description"
#   t.text     "logo"
#   t.boolean  "published",        :default=>false, :null=>false
#   t.boolean  "enrollable",       :default=>false, :null=>false
#   t.string   "registration_key", :limit=>16, :index=>{:name=>"index_courses_on_registration_key", :unique=>true}
#   t.text     "settings"
#   t.boolean  "gamified",         :default=>true, :null=>false
#   t.datetime "start_at",         :null=>false
#   t.datetime "end_at",           :null=>false
#   t.integer  "creator_id",       :null=>false, :index=>{:name=>"fk__courses_creator_id"}, :foreign_key=>{:references=>"users", :name=>"fk_courses_creator_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.integer  "updater_id",       :null=>false, :index=>{:name=>"fk__courses_updater_id"}, :foreign_key=>{:references=>"users", :name=>"fk_courses_updater_id", :on_update=>:no_action, :on_delete=>:no_action}
#   t.datetime "created_at",       :null=>false
#   t.datetime "updated_at",       :null=>false
# end

