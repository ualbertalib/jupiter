module ApplicationHelper
  def page_title(title)
    @page_title ||= []
    @page_title.push(title) if title.present?
    @page_title.join(' | ')
  end
end
