class Aip::V1::CommunitiesController < ApplicationController

  COMMUNITY_INSTITUTIONAL_REPOSITORY_NAME = 'IRCommunity'.freeze

  before_action :load_community
  before_action :ensure_access

  def show
    prefixes = [
      RDF::Vocab::DC,
      ::TERMS[:ual].schema
    ]

    rdf_graph_creator = RdfGraphCreationService.new(@community, prefixes, self_subject)

    statements = [
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: TERMS[:ual].community),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.title, object: @community.title),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.description, object: @community.description),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.accessRights, object: @community.visibility),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.created, object: @community.created_at),
      RDF::Statement(subject: self_subject, predicate: TERMS[:ual].record_created_in_jupiter, object: @community.record_created_at)
    ]

    rdf_graph_creator.graph.insert(*statements)

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
  end

  protected

  def load_community
    @community = Community.find(params[:id])
  end

  def ensure_access
    authorize :aip, :access?
  end

  def self_subject
    RDF::URI(request.url)
  end

end
