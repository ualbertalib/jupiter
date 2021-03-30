class DraftItemDecorator < ApplicationDecorator

  delegate_all

  def html_description
    render_markdown(model.description)
  end

end
