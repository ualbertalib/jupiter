class DOICreateJob < ApplicationJob

  queue_as :default

  def perform(id)
    item = Item.find(id)
    DOIService.new(item).create
  rescue ActiveRecord::RecordNotFound
    thesis = Thesis.find(id)
    DOIService.new(thesis).create
  end

end
