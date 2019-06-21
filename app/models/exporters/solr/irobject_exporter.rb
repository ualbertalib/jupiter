class Exporters::Solr::IrobjectExporter < Exporters::Solr::BaseExporter

  index :visibility, role: [:exact_match, :facet]

end
