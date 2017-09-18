module FileSetsHelper
  def link_to_original_file(file_set)
    url = url_for(controller: :file_sets, action: :download_original, id: file_set.id,
                  file_name: file_set.original_file_name)
    link_to(file_set.original_file_name, url).html_safe
  end
end
