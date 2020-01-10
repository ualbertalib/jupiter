class Exporters::Solr::CommunityExporter < Exporters::Solr::BaseExporter

  indexed_model_name 'ArCommunity'

  index :title, role: [:search, :sort]

  # UAL attributes
  index :fedora3_uuid, role: :exact_match
  index :depositor, role: [:search]

  index :description, role: [:search]
  index :creators, role: :exact_match

  default_sort index: :title, direction: :asc

end
