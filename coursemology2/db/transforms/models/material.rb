module CoursemologyV1::Source
  def_model 'material_folders' do
    belongs_to :parent, class_name: 'MaterialFolder', foreign_key: 'parent_folder_id', inverse_of: nil

    # Sort the records so that parent is always migrated before child.
    scope :tsort, ->() do
      result = all
      result.instance_eval do
        extend TSort

        alias tsort_each_node each

        def tsort_each_child(node, &block)
          [node.parent].each(&block) if node.parent
        end
      end

      result.tsort
    end
  end

  def_model 'materials' do
    belongs_to :folder, class_name: 'MaterialFolder', inverse_of: nil
    has_one :file_upload, as: :owner, inverse_of: nil

    scope :within_courses, ->(course_ids) {
      joins(:folder).where(folder: { course_id: course_ids }).includes(:file_upload)
    }

    def transform_name
      if file_upload
        Pathname.normalize_filename file_upload.original_name
      end
    end

    def transform_creator_id
      if file_upload
        User.transform(file_upload.creator_id) || ::User::DELETED_USER_ID
      end
    end
  end
end
