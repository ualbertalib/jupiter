namespace :jupiter do
  desc 'force garbage collection any orphan attachment blobs on the filesystem. A periodic job handles this normally'
  task gc_blobs: :environment do
    orphan_query = 'SELECT * FROM active_storage_blobs asb WHERE asb.id NOT IN '\
                   '(SELECT distinct blob_id FROM active_storage_attachments)'
    orphan_blobs = ActiveStorage::Blob.find_by_sql(orphan_query)

    puts "Found #{orphan_blobs.count} orphans. Purging..."
    orphan_blobs.each do |blob|
      blob.purge
      print '.'
    end
    puts
    puts 'done!'
  end

  desc 'turn existing filesets into attachments'
  task migrate_filesets: :environment do
    (Item.all + Thesis.all).each do |item|
      item.file_sets.each do |fs|
        fs.unlock_and_fetch_ldp_object do |ufs|
          ufs.fetch_raw_original_file_data do |content_type, io|
            attachment = item.files.attach(io: io, filename: ufs.contained_filename, content_type: content_type).first
            attachment.fileset_uuid = fs.id
            attachment.save
          end
        end
      end
    end
  end
end
