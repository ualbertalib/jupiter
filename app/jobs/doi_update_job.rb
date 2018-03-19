class DOIUpdateJob < ActiveJob::Base
  queue_as :default

  def perform(id)
    item = JupiterCore::LockedLdpObject.find(id, types: [Item, Thesis])
    DOIService.update(item) if item
  end
end
