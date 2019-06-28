ActiveSupport.on_load(:active_storage_blob) do
  # disable expiration of blob ids

  ActiveStorage::Blob.class_eval do
    def signed_id
      key
    end

    def self.find_signed(id)
      find_by(key: id)
    end
  end
end

# Allow tiff as a variable content type and inline to make them available as thumbnails, both lines can likely be removed after upgrading to Rails 6.
Rails.application.config.active_storage.variable_content_types.push 'image/tiff'
Rails.application.config.active_storage.content_types_allowed_inline.push 'image/tiff'
