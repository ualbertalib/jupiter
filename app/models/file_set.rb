class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  solr_index :member_of_collections, solrize_for: :exact_match,
             as: -> { member_of_collections&.to_a.map { |item| item.id} }

  # see also https://github.com/samvera/hydra-works/wiki/Lesson%3A-Add-attached-files
  def self.add_new_to_work(file, unlocked_work)
    fileset = self.new_locked_ldp_object
    fileset.unlock_and_fetch_ldp_object do |unlocked_fileset|
      unlocked_fileset.owner = unlocked_work.owner
      unlocked_fileset.visibility = unlocked_work.visibility
      Hydra::Works::AddFileToFileSet.call(unlocked_fileset, file, :original_file,
                                          update_existing: false, versioning: false)
      unlocked_fileset.member_of_collections += [unlocked_work]
      unlocked_fileset.save!
      unlocked_work.members << unlocked_fileset
      # pull in hydra derivatives, set temp file base
      # Hydra::Works::CharacterizationService.run(fileset.characterization_proxy, filename)
    end
  end

  def item
    item_id = read_solr_index(:member_of_collections)
    return nil unless item_id.present?
    Work.find(item_id.first)
  end

end
