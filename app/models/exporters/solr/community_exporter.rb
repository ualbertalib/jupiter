class Exporters::Solr::CommunityExporter < Exporters::Solr::BaseExporter

  indexed_model_name 'ArCommunity'

  index :title, role: [:search, :sort]

  # UAL attributes
  index :fedora3_uuid, role: :exact_match
  index :depositor, role: [:search]

  index :creators, role: :exact_match

  # Description may contain markdown which isn't particularly useful in a search context. Let's strip this out.
  custom_index :description, role: [:search],
                             as: ->(community) { strip_markdown(community.description) }

  default_sort index: :title, direction: :asc

end
