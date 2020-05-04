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
  task :reindex, [:batch_size] => :environment do |_, args|
    desired_batch_size = args.batch_size.to_i ||= 1000
    puts 'Reindexing all Items and Theses...'
    Item.find_each(batch_size: desired_batch_size, &:save!)
    Thesis.find_each(batch_size: desired_batch_size, &:save!)
    puts 'Reindex completed!'
  end

  desc 'queue all items and theses in the system for preservation'
  task :preserve_all_items_and_theses, [:batch_size] => :environment do |_, args|
    desired_batch_size = args.batch_size.to_i ||= 1000
    puts 'Adding all Items and Theses to preservation queue...'
    Item.find_each(batch_size: desired_batch_size) { |item| item.tap(&:preserve) }
    Thesis.find_each(batch_size: desired_batch_size) { |item| item.tap(&:preserve) }
    puts 'All Items and Theses have been added to preservation queue!'
  end

  desc 'garbage collect any orphan attachment blobs on the filesystem'
  task gc_blobs: :environment do
    orphan_blobs = ActiveStorage::Blob.find_by_sql('SELECT * FROM active_storage_blobs asb WHERE asb.id NOT IN '\
      '(SELECT distinct blob_id FROM active_storage_attachments)')

    puts "Found #{orphan_blobs.count} orphans. Purging..."
    orphan_blobs.each do |blob|
      blob.purge
      print '.'
    end
    puts
    puts 'done!'
  end

  desc 'sayonara ActiveFedora'
  task :get_me_off_of_fedora, [:batch_size] => :environment do |_, args|
    desired_batch_size = args.batch_size.to_i ||= 1000
    puts
    puts 'Preparing Draft Item ...'

    DraftItem.find_each(batch_size: desired_batch_size) do |draft_item|
      draft_item.files_attachments.each do |attachment|
        attachment.upcoming_record_id = draft_item.upcoming_id
        attachment.save!
      end

      draft_item.draft_items_languages.each do |join_record|
        join_record.upcoming_draft_item_id = draft_item.upcoming_id
        join_record.save!
      end
      print '.'
    end

    puts
    puts 'Preparing Draft Thesis ...'

    DraftThesis.find_each(batch_size: desired_batch_size) do |draft_thesis|
      draft_thesis.files_attachments.each do |attachment|
        attachment.upcoming_record_id = draft_thesis.upcoming_id
        attachment.save!
      end
      print '.'
    end

    puts
    puts 'Migrating Communities...'

    Community.find_each(batch_size: desired_batch_size) do |community|
      ArCommunity.from_community(community)
      print '.'
    end

    puts
    puts 'Migrating Collections...'

    Collection.find_each(batch_size: desired_batch_size) do |collection|
      ArCollection.from_collection(collection)
      print '.'
    end

    puts
    puts 'Migrating Items...'

    Item.find_each(batch_size: desired_batch_size) do |item|
      ArItem.from_item(item)
      print '.'
    end

    puts
    puts 'Migrating Theses...'

    Thesis.find_each(batch_size: desired_batch_size) do |thesis|
      ArThesis.from_thesis(thesis)
      print '.'
    end

    puts
    puts 'Finished!'
  end
end
