class Exporters::Solr::AfItemExporter < Exporters::Solr::BaseExporter

  index :title, role: [:search, :sort]

  # UAL attributes
  index :fedora3_uuid, role: :exact_match
  index :depositor, role: [:search]

  index :alternative_title, role: :search
  index :doi, role: :exact_match
  index :embargo_end_date, type: :date, role: [:sort]
  index :fedora3_handle, role: :exact_match
  index :ingest_batch, role: :exact_match
  index :northern_north_america_filename, role: :exact_match
  index :northern_north_america_item_id, role: :exact_match
  index :rights, role: :exact_match
  index :sort_year, type: :integer, role: [:search, :sort, :range_facet]
  index :visibility_after_embargo, role: :exact_match

  index :embargo_history, role: :exact_match
  index :is_version_of, role: :exact_match
  index :member_of_paths, type: :path, role: :pathing

  # See `all_subjects` in including class for faceting
  index :subject, role: :search

  index :creators, type: :json_array, role: :search
  # copying the creator values into an un-json'd field for Metadata consumption
  index :unordered_creators, role: :search

  index :contributors, role: :search
  index :created, role: [:search, :sort]

  # Subject types (see `all_subjects` for faceting)
  index :temporal_subjects, role: :search
  index :spatial_subjects, role: :search

  index :description, type: :text, role: :search
  index :publisher, role: [:search, :facet]

  index :languages, role: [:search, :facet]
  index :license, role: :search

  # Note also the `item_type_with_status` below for searching, faceting and forms
  index :item_type, role: :exact_match
  index :source, role: :exact_match
  index :related_link, role: :exact_match
  index :publication_status, role: :exact_match

  # Solr only
  custom_index :doi_without_label, role: :exact_match,
                                   as: ->(item) { item.doi.gsub('doi:', '') if item.doi.present? }

  # This combines both the controlled vocabulary codes from item_type and published_status above
  # (but only for items that are articles)
  custom_index :item_type_with_status, role: :facet, as: ->(item) { item.item_type_with_status_code }

  # Combine creators and contributors for faceting (Thesis also uses this index)
  # Note that contributors is converted to an array because it can be nil
  custom_index :all_contributors, role: :facet, as: ->(item) { item.creators + item.contributors.to_a }

  # Combine all the subjects for faceting
  custom_index :all_subjects, role: :facet, as: ->(item) { item.all_subjects }

  default_sort index: :title, direction: :asc

end
