class CollectionDecorator < ApplicationDecorator

  delegate_all

  def description
    markdown(model.description)
  end

end
