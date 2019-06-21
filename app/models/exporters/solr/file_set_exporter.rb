class Exporters::Solr::FileSetExporter < Exporters::Solr::BaseExporter

  index :contained_filename, role: :exact_match
  index :sitemap_link, role: :exact_match

  custom_index :item, role: :search, as: ->(file_set) {
    ids = []
    file_set.unlock_and_fetch_ldp_object do |uo|
      uo.send(:member_of_collections)&.map do |member|
        ids << member.id
      end
    end
    ids
  }

end
