class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  belongs_to :item, using_existing_association: :member_of_collections
  def item
    item_id = read_solr_index(:member_of_collections)
    return nil unless item_id.present?
    Item.find(item_id.first)
  end

  [:original_file_name, :original_uri, :original_mime_type].each do |name|
    define_method(name) do
      read_solr_index(name)&.first
    end
  end

  def original_size_bytes
    read_solr_index(:original_size_bytes)&.first&.to_i
  end

  unlocked do
    # For some reason, the file name isn't always set in original_file
    # (Race condition in Hydra::Works::AddFileToFileSet ???)
    attr_accessor :original_file_name
  end

end
