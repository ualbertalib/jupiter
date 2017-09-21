class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  solr_index :member_of_collections, solrize_for: :exact_match, as: -> { member_of_collections&.map(&:id) }
  solr_index :original_file_name, solrize_for: :exact_match,
                                  as: -> { original_file&.file_name&.first || original_file_name }
  solr_index :original_uri, solrize_for: :exact_match, as: -> { original_file&.uri&.to_s }
  solr_index :original_size_bytes, solrize_for: :exact_match, as: -> { original_file&.size }
  solr_index :original_mime_type, solrize_for: :exact_match, as: -> { original_file&.mime_type }

  # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
  def self.add_new_to_item(file, unlocked_item)
    new_locked_ldp_object.unlock_and_fetch_ldp_object do |unlocked_fileset|
      unlocked_fileset.owner = unlocked_item.owner
      unlocked_fileset.visibility = unlocked_item.visibility
      Hydra::Works::AddFileToFileSet.call(unlocked_fileset, file, :original_file,
                                          update_existing: false, versioning: false)
      unlocked_fileset.member_of_collections += [unlocked_item]
      # Temporarily cache the file name for storing in Solr
      unlocked_fileset.original_file_name = file.original_filename
      unlocked_fileset.save!
      unlocked_item.members << unlocked_fileset
      # pull in hydra derivatives, set temp file base
      # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
    end
  end

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
