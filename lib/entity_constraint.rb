class EntityConstraint

  def initialize
    @entity_list = [
      Item.name.underscore.pluralize,
      Thesis.name.underscore.pluralize
    ]
  end

  def matches?(request)
    @entity_list.include? request[:entity]
  end

end
