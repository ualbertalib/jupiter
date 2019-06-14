class Exporters::Solr::ItemExporter < Exporters::Solr::BaseExporter

  # exports Item

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
  virtual_index :doi_without_label, role: :exact_match,
                                    as: ->(item) { item.doi.gsub('doi:', '') if item.doi.present? }

  # This combines both the controlled vocabulary codes from item_type and published_status above
  # (but only for items that are articles)
  virtual_index :item_type_with_status, role: :facet, as: ->(item) { item.item_type_with_status_code }

  # Combine creators and contributors for faceting (Thesis also uses this index)
  # Note that contributors is converted to an array because it can be nil
  virtual_index :all_contributors, role: :facet, as: ->(item) { item.creators + item.contributors.to_a }

  # Combine all the subjects for faceting
  virtual_index :all_subjects, role: :facet, as: ->(item) { item.all_subjects }

end
