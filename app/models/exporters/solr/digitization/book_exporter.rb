class Exporters::Solr::Digitization::BookExporter < Exporters::Solr::BaseExporter

  indexed_model_name 'DigBook'

  index :title, role: [:search, :sort]

  index :alternative_title, role: :search
  index :rights, role: :exact_match
  index :visibility_after_embargo, role: :exact_match

  # See `all_subjects` in including class for faceting
  index :topical_subject, role: :search

  index :created, role: [:search, :sort]

  # Subject types (see `all_subjects` for faceting)
  index :temporal_subjects, role: :search
  index :spatial_subjects, role: :search

  index :description, type: :text, role: :search
  index :publisher, role: [:search, :facet]

  index :languages, role: [:search, :facet]
  index :genre, role: [:search, :facet]
  index :place_of_publication, role: [:search, :facet]

  index :resource_type, role: :exact_match

  # Combine all the subjects for faceting
  custom_index :all_subjects, role: :facet, as: ->(book) { book.all_subjects }

  custom_index :all_contributors, role: :facet, as: ->(book) { book.all_contributors }

  default_sort index: :title, direction: :asc

  fulltext_searchable :description

end
