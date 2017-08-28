module ApplicationHelper
  def page_title(page_title)
    base_title = I18n.t('site_name')
    if page_title.blank?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end
end
