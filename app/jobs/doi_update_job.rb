class DOIUpdateJob < ApplicationJob

  queue_as :default

  def perform(id)
    item = JupiterCore::LockedLdpObject.find(id, types: [Item, Thesis])
    DOIService.new(item).update if item
  end

end
