class DOIRemoveJob < ApplicationJob

  queue_as :default

  def perform(doi)
    DOIService.remove(doi)
  end

end
