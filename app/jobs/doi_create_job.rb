class DOICreateJob < ApplicationJob

  queue_as :default

  def perform(id)
    item = JupiterCore::LockedLdpObject.find(id, types: [Item, Thesis])
    DOIService.new(item).create if item
  end

end
