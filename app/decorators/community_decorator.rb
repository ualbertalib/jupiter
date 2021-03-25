class CommunityDecorator < ApplicationDecorator

  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def description
    markdown(model.description)
  end

end
