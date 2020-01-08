
# Dir["#{Rails.root}/lib/ext/*.rb"].each { |file| require file }

Dir[Rails.root.join("lib/core_ext/**/*.rb")].each { |f| require f }

# ActiveStorage::Blob.include ::ActiveStorageBlobExtension
# ActiveStorage::Attachment.include ActiveStorageAttachmentExtension
