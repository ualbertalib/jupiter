module FileSetsHelper
  def fileset_uri(fileset, action)
    # The slash in the controller name below allows this to work in admin namespace
    url_for(controller: '/file_sets', action: action, id: fileset.id,
            file_name: fileset.contained_filename)
  end
end
