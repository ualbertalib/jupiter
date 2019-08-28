namespace :jupiter do
  # Wizard has potential of leaving stale inactive draft items around,
  # For example if someone goes to the deposit screen and then leaves
  # a draft item gets created and left in an inactive state.
  # This rake task is to cleanup these inactive draft items
  desc 'removes stale inactive drafts from the database'
  task remove_inactive_drafts: :environment do
    # Find all the inactive draft items older than yesterday
    inactive_draft_items = DraftItem.drafts.where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    puts "Deleting #{inactive_draft_items.count} Inactive Draft Items..."

    # delete them all
    inactive_draft_items.destroy_all

    # Find all the inactive draft theses older than yesterday
    inactive_draft_theses = DraftThesis.drafts
                                       .where('DATE(created_at) < DATE(?)', Date.yesterday).where(status: :inactive)
    puts "Deleting #{inactive_draft_theses.count} Inactive Draft Theses..."

    # delete them all
    inactive_draft_theses.destroy_all

    puts 'Cleanup of Inactive Draft Items and Draft Theses now completed!'
  end

  desc 'fetch and unlock every object then save'
  task reindex: :environment do
    puts 'Reindexing all Items and Theses...'
    (Item.all + Thesis.all).each { |item| item.save! }
    puts 'Reindex completed!'
  end

  desc 'queue all items and theses in the system for preservation'
  task preserve_all_items_and_theses: :environment do
    puts 'Adding all Items and Theses to preservation queue...'
    (Item.all + Thesis.all).each { |item| item.unlock_and_fetch_ldp_object(&:preserve) }
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
  task get_me_off_of_fedora: :environment do
    puts
    puts 'Preparing Draft Item ...'

    DraftItem.all.each do |draft_item|
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

    DraftThesis.all.each do |draft_thesis|
      draft_thesis.files_attachments.each do |attachment|
        attachment.upcoming_record_id = draft_thesis.upcoming_id
        attachment.save!
      end
      print '.'
    end

    puts
    puts 'Migrating Communities...'

    Community.all.each do |community|
      ArCommunity.from_community(community)
      print '.'
    end

    puts
    puts 'Migrating Collections...'

    Collection.all.each do |collection|
      ArCollection.from_collection(collection)
      print '.'
    end

    puts
    puts 'Migrating Items...'

    Item.all.each do |item|
      ArItem.from_item(item)
      print '.'
    end

    puts
    puts 'Migrating Theses...'

    Thesis.all.each do |thesis|
      ArThesis.from_thesis(thesis)
      print '.'
    end

    puts
    puts 'Finished!'
  end

  desc 'turn existing filesets into attachments'
  task migrate_filesets: :environment do
    total_count =Item.count + Thesis.count
    progress = 0

    puts "Migrating filesets for #{total_count} items..."
    # Processing these separately to cut down on the size of the Solr document we pull back in the query
    # if we see this task getting pinned in GC we may need to further refine this to process records in more
    # granular chunks
   Item.all.each do |item|
      migrate_fileset_item(item)
      print '.'
      progress += 1
    end
    puts
    puts "#{progress} items migrated. Now migrating theses..."
    progress = 0
    Thesis.all.each do |item|
      migrate_fileset_item(item)
      print '.'
      progress += 1
    end
    puts
    puts "#{progress} theses migrated."
    puts
    puts 'done!'
  end

  def migrate_fileset_item(item)
    # re-migrate if something went wrong previously
    item.files.purge

    item.file_sets.each do |fs|
      fs.unlock_and_fetch_ldp_object do |ufs|
        ufs.fetch_raw_original_file_data do |content_type, io|
          attachment = item.files.attach(io: io, filename: ufs.contained_filename, content_type: content_type).first
          attachment.fileset_uuid = fs.id
          attachment.save
        end
      end
    end
    item.set_thumbnail(item.files.first) if item.files.first.present?
  rescue StandardError => e
    puts
    puts "error migrating #{item.class}: #{item.id} -- reported error was '#{e.message}'"
    puts 'moving on to next item'
    puts
  end
end
