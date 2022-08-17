class GarbageCollectBlobsJob

  # Sidekiq Unique Jobs doesn't work with ActiveJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executing, queue: 'default'

  # Since there is a many-many relationship between Items/DraftItems and blobs, we can't use a purge callback on deletion of an attachment.
  # Therefore we need a process for removing blobs that become orphaned over time as all of their associated attachments cease to exist.
  # See the note on: https://github.com/rails/rails/blob/master/activestorage/app/models/active_storage/attachment.rb#L5-L8

  # This query is to get any ActiveStorage::Blob ids that are not in the ActiveStorage::Attachment table - meaning that the blob was orphaned as there is no more association found within the attachment table.
  # This is equivalent to:
  # ActiveStorage::Blob.where([
  # "id NOT IN (?)",
  # ActiveStorage::Attachment.pluck("blob_id")
  # )]
  # but faster.

  def perform
    orphan_query = 'SELECT id FROM active_storage_blobs asb EXCEPT SELECT DISTINCT blob_id ' \
                   'FROM active_storage_attachments asa INNER JOIN active_storage_blobs asb ON asb.id=asa.blob_id'
    orphan_blobs = ActiveStorage::Blob.find_by_sql(orphan_query)
    orphan_blobs.each(&:purge)
  end

end
