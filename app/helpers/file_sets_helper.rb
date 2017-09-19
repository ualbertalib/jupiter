module FileSetsHelper
  def view_original_file_button(file_set)
    original_file_button(file_set, :view_original, t('.view'))
  end

  def download_original_file_button(file_set)
    original_file_button(file_set, :download_original, t('.download'))
  end

  private

  def original_file_button(file_set, action, text)
    url = url_for(controller: :file_sets, action: action, id: file_set.id,
                  file_name: file_set.original_file_name)
    link_to(text, url, class: 'btn btn-outline-primary').html_safe
  end
end
