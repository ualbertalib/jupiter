namespace :jupiter do
  # Wizard has potential of leaving stale inactive draft items around,
  # For example if someone goes to the deposit screen and then leaves
  # a draft item gets created and left in an inactive state.
  # This rake task is to cleanup these inactive draft items
  desc 'removes stale inactive drafts from the database'
  task remove_inactive_drafts: :environment do
    # Find all the inactive draft items older than yesterday
    inactive_draft_items = DraftItem.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    puts "Deleting #{inactive_draft_items.count} Inactive Draft Items..."

    # delete them all
    inactive_draft_items.destroy_all

    # Find all the inactive draft theses older than yesterday
    inactive_draft_theses = DraftThesis.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    puts "Deleting #{inactive_draft_theses.count} Inactive Draft Theses..."

    # delete them all
    inactive_draft_theses.destroy_all

    puts 'Cleanup of Inactive Draft Items and Draft Theses now completed!'
  end

  desc 'fetch and unlock every object then save'
  task reindex: :environment do
    puts 'Reindexing all Items and Theses...'
    (Item.all + Thesis.all).each { |item| item.unlock_and_fetch_ldp_object(&:save!) }
    puts 'Reindex completed!'
  end

  desc 'queue all items and theses in the system for preservation'
  task preserve_all_items_and_theses: :environment do
    puts 'Adding all Items and Theses to preservation queue...'
    (Item.all + Thesis.all).each { |item| item.unlock_and_fetch_ldp_object(&:preserve) }
    puts 'All Items and Theses have been added to preservation queue!'
  end
end
