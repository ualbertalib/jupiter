class FileSet < JupiterCore::LockedLdpObject

  ldp_object_includes Hydra::Works::FileSetBehavior

  # BUG with has_attr when no solrize_for is specified, the property is simply nil. better to complain
  has_attribute :contained_filename, ::RDF::Vocab::DC.title, solrize_for: :exact_match

  belongs_to :item, using_existing_association: :member_of_collections
end
