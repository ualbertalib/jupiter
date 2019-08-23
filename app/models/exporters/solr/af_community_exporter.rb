class Exporters::Solr::AfCommunityExporter < Exporters::Solr::BaseExporter

  index :title, role: [:search, :sort]

  # UAL attributes
  index :fedora3_uuid, role: :exact_match
  index :depositor, role: [:search]

  index :description, role: [:search]
  index :creators, role: :exact_match

end
