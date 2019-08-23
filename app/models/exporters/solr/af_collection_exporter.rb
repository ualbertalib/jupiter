class Exporters::Solr::AfCollectionExporter < Exporters::Solr::BaseExporter

  index :title, role: [:search, :sort]

  # UAL attributes
  index :fedora3_uuid, role: :exact_match
  index :depositor, role: [:search]

  index :community_id, type: :path, role: :pathing

  index :description, role: [:search]
  index :restricted, type: :boolean, role: :exact_match
  index :creators, role: :exact_match

  # TODO: refactor this next line and move the title into Fedora, if we're still on Fedora at that point.
  #
  # We got lucky in that there are not expected to be a large number of Collections in this phase of Jupiter
  # but using +additional_search_index+ to store data that isn't recreatable solely by inspecting this object's
  # Fedora record creates data-ordering issues that are complicated to work around during Solr-index recovery
  # scenarios. See recover.rake for information on the particular problems this is causing and why we want to
  # eliminate it.
  custom_index :community_title, role: :sort,
                                 as: lambda { |collection|
                                       Community.find(collection.community_id).title if collection.community_id.present?
                                     }

end
