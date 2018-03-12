namespace :cleanup do
  # Wizard has potential of leaving stale inactive draft items around,
  # For example if someone goes to the deposit screen and then leaves
  # a draft item gets created and left in an inactive state.
  # This rake task is to cleanup these inactive draft items
  desc 'removes stale inactive draft items from the database'
  task inactive_draft_items: :environment do
    # Find all the inactive draft items older than yesterday
    inactive_draft_items = DraftItem.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)

    puts "Deleting #{inactive_draft_items.count} Inactive Draft Items..."

    # delete them all
    inactive_draft_items.destroy_all

    puts 'Cleanup of Inactive Draft Items now completed!'
  end

  desc 'fetch and unlock every object then save'
  task reindex: :environment do
    puts 'Reindexing all Items and Theses...'
    (Item.all + Thesis.all).each { |item| item.unlock_and_fetch_ldp_object(&:save!) }
    puts 'Reindex completed!'
  end
end
