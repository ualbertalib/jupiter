require Rails.root.join('app/services/read_only_service')

namespace :jupiter do
  desc 'fetch every object then update solr'
  task :reindex, [:batch_size] => :environment do |_, args|
    desired_batch_size = if args.batch_size.present?
                           args.batch_size.to_i
                         else
                           1000
                         end
    puts 'Reindexing all Items and Theses...'

    count = 0
    Item.find_each(batch_size: desired_batch_size) do |item|
      item.update_solr
      count += 1
      print '.' if count % 20 == 0
    end

    puts
    puts "Reindexed #{count} Items. Moving on to Theses..."

    count = 0
    Thesis.find_each(batch_size: desired_batch_size) do |thesis|
      thesis.update_solr
      count += 1
      print '.' if count % 20 == 0
    end
    puts
    puts "Reindexed #{count} Theses."
    puts

    puts 'Reindexing all Communities and Collections...'
    count = 0
    Community.find_each(batch_size: desired_batch_size) do |community|
      community.update_solr
      count += 1
      print '.' if count % 20 == 0
    end

    puts
    puts "Reindexed #{count} Communities. Moving on to Collections..."

    count = 0
    Collection.find_each(batch_size: desired_batch_size) do |collection|
      collection.update_solr
      count += 1
      print '.' if count % 20 == 0
    end
    puts
    puts "Reindexed #{count} Collections."
    puts

    puts 'Reindex completed!'
  end

  desc 'queue all items and theses in the system for preservation'
  task :preserve_all_items_and_theses, [:before_date, :batch_size] => :environment do |_, args|
    desired_batch_size = if args.batch_size.present?
                           args.batch_size.to_i
                         else
                           1000
                         end

    begin
      before_date = Date.parse(args.before_date) if args.before_date.present?
    rescue ArgumentError
      puts "#{args.before_date} is not a valid date"
      exit 1
    end

    if before_date.present?
      puts "Adding Items and Theses on or after #{before_date} to preservation queue..."
      items = Item.updated_on_or_after(before_date)
      items.find_each(batch_size: desired_batch_size, &:push_entity_for_preservation)
      theses = Thesis.updated_on_or_after(before_date)
      theses.find_each(batch_size: desired_batch_size, &:push_entity_for_preservation)
      puts "#{items.count} Items and #{theses.count} Theses have been added to preservation queue!"
    else
      puts 'Adding all Items and Theses to preservation queue...'
      Item.find_each(batch_size: desired_batch_size, &:push_entity_for_preservation)
      Thesis.find_each(batch_size: desired_batch_size, &:push_entity_for_preservation)
      puts 'All Items and Theses have been added to preservation queue!'
    end
  end

  desc 'clear the preservation queue'
  task clear_preservation_queue: :environment do
    queue_name = Rails.application.secrets.preservation_queue_name

    queue = ConnectionPool.new(size: 1, timeout: 5) { RedisClient.current }
    success = queue.with { |connection| connection.del queue_name }
    puts case success
         when 1
           "#{queue_name} deleted"
         when 0
           "#{queue_name} doesn't exist"
         else
           'Well this is unexpected!'
         end
  end

  desc 'garbage collect any orphan attachment blobs on the filesystem'
  task gc_blobs: :environment do
    orphan_blobs = ActiveStorage::Blob.find_by_sql('SELECT * FROM active_storage_blobs asb WHERE asb.id NOT IN ' \
                                                   '(SELECT distinct blob_id FROM active_storage_attachments)')

    puts "Found #{orphan_blobs.count} orphans. Purging..."
    orphan_blobs.each do |blob|
      blob.purge
      print '.'
    end
    puts
    puts 'done!'
  end

  # rubocop:disable Rails/SkipsModelValidations
  # what if, Rubocop, skipping validations were the entire point?
  desc 'sayonara ActiveFedora'
  task :get_me_off_of_fedora, [:batch_size] => :environment do |_, args|
    desired_batch_size = args.batch_size.to_i ||= 1000
    puts
    puts 'Preparing Attachments'
    ActiveStorage::Attachment.find_each(batch_size: desired_batch_size) do |attachment|
      attachment.update_columns(upcoming_blob_id: attachment.blob&.upcoming_id)

      print '.'
    end

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

      draft_item.update_columns(upcoming_thumbnail_id: draft_item.thumbnail&.blob&.upcoming_id)

      print '.'
    end

    puts
    puts 'Preparing Draft Thesis ...'

    DraftThesis.find_each(batch_size: desired_batch_size) do |draft_thesis|
      draft_thesis.files_attachments.each do |attachment|
        attachment.upcoming_record_id = draft_thesis.upcoming_id
        attachment.save!
      end

      draft_thesis.update_columns(upcoming_thumbnail_id: draft_thesis.thumbnail&.blob&.upcoming_id)

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
  # rubocop:enable Rails/SkipsModelValidations

  desc 'enable read only mode'
  task enable_read_only_mode: :environment do
    read_only_mode = ReadOnlyService.new
    puts 'Enabling read only mode...'
    read_only_mode.enable
    puts 'Done!'
  end

  desc 'disable read only mode'
  task disable_read_only_mode: :environment do
    read_only_mode = ReadOnlyService.new
    puts 'Disabling read only mode...'
    read_only_mode.disable
    puts 'Done!'
  end
end
