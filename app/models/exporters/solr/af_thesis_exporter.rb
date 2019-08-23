class Exporters::Solr::AfThesisExporter < Exporters::Solr::BaseExporter

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

  # Dublin Core attributes
  index :abstract, type: :text, role: :search
  # Note: language is single-valued for Thesis, but languages is multi-valued for Item
  # See below for faceting
  index :language, role: :search
  index :date_accepted, type: :date, role: :exact_match
  index :date_submitted, type: :date, role: :exact_match

  # BIBO
  index :degree, role: :exact_match

  # SWRC
  index :institution, role: :exact_match

  # UAL attributes
  # This one is faceted in `all_contributors`, along with the Item creators/contributors
  index :dissertant, role: [:search, :sort]
  index :graduation_date, role: [:search, :sort]
  index :thesis_level, role: :exact_match
  index :proquest, role: :exact_match
  index :unicorn, role: :exact_match

  index :specialization, role: :search
  index :departments, type: :json_array, role: [:search]
  index :supervisors, type: :json_array, role: [:search]
  index :committee_members, role: :exact_match
  index :unordered_departments, role: :search
  index :unordered_supervisors, role: :exact_match

  # This gets mixed with the item types for `Item`
  custom_index :item_type_with_status,
               role: :facet,
               as: ->(thesis) { thesis.item_type_with_status_code }

  # Dissertants are indexed with the Item creators/contributors
  custom_index :all_contributors, role: :facet, as: ->(thesis) { [thesis.dissertant] }

  # Index subjects with Item subjects (topical, temporal, etc).
  custom_index :all_subjects, role: :facet, as: ->(thesis) { thesis.subject }

  # Making `language` consistent with Item `languages`
  custom_index :languages,
               role: :facet,
               as: ->(thesis) { [thesis.language] }

  custom_index :doi_without_label, role: :exact_match,
                                   as: ->(thesis) { thesis.doi.gsub('doi:', '') if thesis.doi.present? }

end
