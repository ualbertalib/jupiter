class GarbageCollectBlobsJob < ApplicationJob

  queue_as :default

  # Since there is a many-many relationship between Items/DraftItems and blobs, we can't use a purge callback on deletion of an attachment.
  # Therefore we need a process for removing blobs that become orphaned over time as all of their associated attachments cease to exist. 
  # See the note on: https://github.com/rails/rails/blob/master/activestorage/app/models/active_storage/attachment.rb#L5-L8

  def perform
    orphan_blobs = ActiveStorage::Blob.find_by_sql("SELECT * FROM active_storage_blobs asb WHERE asb.id NOT IN (SELECT distinct blob_id FROM active_storage_attachments)")
    orphan_blobs.each(&:purge)
  end

end
