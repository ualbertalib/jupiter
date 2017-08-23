module ApplicationHelper
  def page_title(page_title)
    base_title = 'ERA'
    if page_title.blank?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end
end
