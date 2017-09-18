module FileSetsHelper
  def original_file_url(file_set)
    url_for(controller: :file_sets, action: :download_original, id: file_set.id,
            file_name: file_set.original_file_name)
  end
end
