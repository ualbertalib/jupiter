class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  has_attribute :is_member_of, ::VOCABULARY[:ualib].path, solrize_for: :pathing

  def item
    Work.find(is_member_of)
  end

end
