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
