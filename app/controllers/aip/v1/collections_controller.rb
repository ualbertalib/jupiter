class Aip::V1::CollectionsController < ApplicationController

  include GraphCreation

  COLLECTION_INSTITUTIONAL_REPOSITORY_NAME = 'IRCollection'.freeze

  before_action :load_and_authorize_collection

  def show_collection
    # TODO: Check information included with metadata team, this set is only a
    # placeholder.
    prefixes = [
      RDF::Vocab::DC,
      ::TERMS[:ual].schema
    ]

    graph = create_graph(@collection, prefixes)

    graph << rdf_type_statement(RDF::Vocab::PCDM.Collection)

    graph << RDF::Statement(
      subject: self_subject,
      predicate: ::TERMS[:fedora].has_model,
      object: COLLECTION_INSTITUTIONAL_REPOSITORY_NAME
    )

    render plain: graph.to_n3, status: :ok
  end

  protected

  def load_and_authorize_collection
    @collection = Collection.find(params[:id])
    authorize @collection
  end

end
