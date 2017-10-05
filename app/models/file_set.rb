class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  belongs_to :item, using_existing_association: :member_of_collections

end
