class Exporters::Solr::FileSetExporter < Exporters::Solr::BaseExporter

  index :contained_filename, role: :exact_match
  index :sitemap_link, role: :exact_match

  # we need to work around the fact that Hydra::Works::FileSetBehavior
  # declares member_of_collections on the raw ActiveFedora object
  # by unlocking the object being indexed here and collecting its
  # IDs at index time. We renamed this to "item" in fileset
  # to reduce confusion about the fact that a fileset isn't a member of any collections,
  # despite the name.
  #
  # TODO: this is messy and papering over a Hydra issue -- it goes away when ActiveFedora does
  custom_index :item, role: :search, as: lambda { |file_set|
    ids = []
    file_set.unlock_and_fetch_ldp_object do |uo|
      uo.send(:member_of_collections)&.map do |member|
        ids << member.id
      end
    end
    ids
  }

end
