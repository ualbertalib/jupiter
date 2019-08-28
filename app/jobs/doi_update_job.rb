class DOIUpdateJob < ApplicationJob

  queue_as :default

  def perform(id)
    item = Item.find(id)
    DOIService.new(item).update
  rescue ActiveRecord::RecordNotFound
    thesis = Thesis.find(id)
    DOIService.new(thesis).update
  end
end
