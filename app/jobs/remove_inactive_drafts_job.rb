class RemoveInactiveDraftsJob < ApplicationJob

  # Deposit Wizard has potential of leaving stale inactive draft objects around,
  # For example if someone goes to the deposit screen and then leaves,
  # a draft object gets created and left in an inactive state.
  # This job will cleanup these inactive draft objects
  #
  # We will queue this job via sidekiq-cron once a week to remove any
  # stale inactive drafts from the database

  queue_as :default

  def perform
    # Find all the inactive draft items older than yesterday
    inactive_draft_items = DraftItem.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    # delete them all
    inactive_draft_items.destroy_all

    # Find all the inactive draft theses older than yesterday
    inactive_draft_theses = DraftThesis.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    # delete them all
    inactive_draft_theses.destroy_all
  end

end
