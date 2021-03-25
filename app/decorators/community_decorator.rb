class CommunityDecorator < ApplicationDecorator

  delegate_all

  def description
    markdown(model.description)
  end

end
