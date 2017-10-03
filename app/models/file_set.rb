class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior
  use_existing_association :member_of_collections, using_name: :items

end
