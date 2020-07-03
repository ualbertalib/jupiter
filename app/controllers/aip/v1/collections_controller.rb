class Aip::V1::CollectionsController < ApplicationController

  COLLECTION_INSTITUTIONAL_REPOSITORY_NAME = 'IRCollection'.freeze

  before_action :load_collection
  before_action :ensure_access

  def show
    # TODO: Check information included with metadata team, this set is only a
    # placeholder.
    prefixes = [
      RDF::Vocab::DC,
      ::TERMS[:ual].schema
    ]

    rdf_graph_creator = RdfGraphCreationService.new(@collection, prefixes, self_subject)

    statement_definitions = [
      { subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PCDM.Collection },
      { subject: self_subject, predicate: ::TERMS[:fedora].has_model, object: COLLECTION_INSTITUTIONAL_REPOSITORY_NAME }
    ]

    statement_definitions.each do |statement_definition|
      rdf_graph_creator.insert(RDF::Statement(statement_definition))
    end

    render plain: rdf_graph_creator.to_n3, status: :ok
  end

  protected

  def load_collection
    @collection = Collection.find(params[:id])
  end

  def ensure_access
    authorize :aip, :access?
  end

  def self_subject
    RDF::URI(request.url)
  end

end
