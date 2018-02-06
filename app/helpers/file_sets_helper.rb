module FileSetsHelper
  def fileset_uri(fileset, action)
    # The slash in the controller name below allows this to work in admin namespace
    route = { controller: '/file_sets', action: action, id: fileset.item, file_set_id: fileset.id }
    route[:file_name] = fileset.contained_filename unless action == :download
    url_for(route)
  end
end
