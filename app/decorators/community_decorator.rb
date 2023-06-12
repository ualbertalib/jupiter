class CommunityDecorator < ApplicationDecorator

  delegate_all

  def description
    render_markdown(model.description)
  end

end
