class CommunityDecorator < Draper::Decorator

  include MarkdownDecorator

  delegate_all

  def description
    markdown(model.description)
  end

end
