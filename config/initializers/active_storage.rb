Rails.configuration.to_prepare do
  ActiveStorage::Attachment.send :include, ::ActiveStorageAttachmentExtension
  ActiveStorage::Blob.send :include, ::ActiveStorageBlobExtension
end

# Allow tiff as a variable content type and inline to make them available as thumbnails, both lines can likely be removed after upgrading to Rails 6.
Rails.application.config.active_storage.variable_content_types.push 'image/tiff'
Rails.application.config.active_storage.content_types_allowed_inline.push 'image/tiff'
