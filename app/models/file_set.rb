class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior

  has_attribute :contained_filename, ::RDF::Vocab::DC.title, solrize_for: :exact_match
  #  has_attribute :original_uri, ::, solrize_for: :exact_match

  belongs_to :item, using_existing_association: :member_of_collections

end
