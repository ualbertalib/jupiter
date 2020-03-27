class Aip::V1::CollectionsController < ApplicationController

  include GraphCreation

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

    graph << prepare_statement(
      subject: self_subject,
      predicate: RDF::URI.new('info:fedora/fedora-system:def/model#hasModel'),
      object: 'IRCollection'
    )

    render plain: graph.to_n3, status: :ok
  end

  protected

  def load_and_authorize_collection
    authorize @collection = Collection.find(params[:id])
  end

end
