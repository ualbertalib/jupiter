class ChangeByteSizeInActiveStorageBlob < ActiveRecord::Migration[6.1]
  def change
    change_column :active_storage_blobs, :byte_size, :bigint
  end
end
