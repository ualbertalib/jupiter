module FileSetsHelper
  def fileset_uri(fileset, action)
    url_for(controller: '/file_sets', action: action, id: fileset.id,
            file_name: fileset.contained_filename)
  end
end
