class Aip::V1::CollectionsController < ApplicationController

  COLLECTION_INSTITUTIONAL_REPOSITORY_NAME = 'IRCollection'.freeze

  before_action :load_collection
  before_action :ensure_access

  def show
    # ::TERMS[:ual].schema doesn't seem to be added as a prefix and path is added
    prefixes = [
      RDF::Vocab::DC,
      RDF::Vocab::PCDM,
      ::TERMS[:ual].schema
    ]

    rdf_graph_creator = RdfGraphCreationService.new(@collection, prefixes, self_subject)
    statements = [
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PCDM.Collection),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::PCDM.memberOf, object: @collection.community_id),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.title, object: @collection.title),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.description, object: @collection.description),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.accessRights, object: @collection.visibility),
      RDF::Statement(subject: self_subject, predicate: TERMS[:ual].restricted_collection,
                     object: @collection.restricted),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.created, object: @collection.created_at),
      RDF::Statement(subject: self_subject, predicate: TERMS[:ual].record_created_in_jupiter,
                     object: @collection.record_created_at)
    ]

    rdf_graph_creator.graph.insert(*statements)

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
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
