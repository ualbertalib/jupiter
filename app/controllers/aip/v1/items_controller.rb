require 'rdf/n3'
require 'rdf/vocab'
require 'acts_as_rdfable'
import RDF
import ActsAsRdfable

class Aip::V1::ItemsController < ApplicationController

  before_action :load_item, only: [:show, :file_sets]
  before_action :load_and_authorize_file, only: [:file_set, :fixity_file, :download_file, :original_file]

  def show
    authorize @item
    @graph = RDF::Graph.new
    subject = RDF::URI(request.url)

  # everything in the following namespaces: dc, ns002, ns001, ns003, ns008, ns005, ns009, ns010, ebucore;
  # ns004:hasModel
  # fedora:created, fedora:createdBy, fedora:lastmodified, fedora:lastmodifiedBy, fedora:writable


    annotations = get_prefixed_predicates(@item)

    # @item.rdf_annotations.each do |rdf_annotation|
    annotations.each do |rdf_annotation|
      column = rdf_annotation.column
      value = @item.send(column)

      add_statement!(
        subject: subject,
        predicate: rdf_annotation.predicate,
        object: value
      )
    end

    # handle files separately since they are not a part of the acts_as_rdfable
    # table entries

    @item.files.each do |file|
      fileset_url = "#{request.original_url}/filesets/#{file.fileset_uuid}"
      add_statement!(
        subject: subject,
        predicate: CONTROLLED_VOCABULARIES[:pcdm].has_member,
        object: fileset_url
      )
    end

    # Add owners email seperatedly because there is currently no predicate set
    # to specify this relation directly

    add_statement!(
      subject: subject,
      predicate: RDF::Vocab::BIBO.owner,
      object: @item.owner.email
    )

    triples = @graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def file_sets
    authorize @item

    # The underscore for xml.uuid_ is intentional. Nokogiri builder makes
    # use of method_missing to create its xml model. There could be
    # problems with preexisting methods so we play it safe and add an underscore
    # to avoid unintended behaviuor. You can find more info here:
    # https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Builder

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.file_order do
        @item.files.each do |file|
          xml.uuid_ file.fileset_uuid
        end
      end
    end
    render xml: builder.to_xml
  end

  def file_set
    # XXX Missing
    # everything in the following namespaces: ns002, ns001, ns003, ns005, ebucore;
    # ns004:hasModel
    # fedora:created, fedora:createdBy, fedora:lastmodified, fedora:lastmodifiedBy, fedora:writable
    render plain: 'file_set'
  end

  def fixity_file
    # XXX Missing
    # everything in the premis namespace http://www.loc.gov/premis/rdf/v1#

    # predicates = RDF::Vocab::PREMIS

    render plain: 'fixity_file'
  end

  def download_file
    send_data(
      ActiveStorage::Blob.service.download(@file.blob.key),
      disposition: 'attachment',
      type: @file.blob.content_type,
      filename: @file.filename.to_s
    )
  end

  def original_file
    # XXX Missing
    # everything in the following namespaces: fedora, ebucore, premis, ns015, ns018, ns014, dc
    render plain: 'original_file'
  end

  private

  def load_item
    @item = Item.find(params[:id])
  end

  def get_prefixed_predicates(object, *prefixes)
    result = []
    ActsAsRdfable.add_annotation_bindings!(object)

    prefixes.each do |prefix|
      result << object.rdf_annotations
                      .where('predicate like :prefix', prefix: "#{prefix}%")
    end

    result
  end

  def add_statement!(subject:, predicate:, object:)
    return if object.nil?

    object = [object] unless object.is_a?(Array)
    rdf_predicate = RDF::Vocabulary::Term.new(predicate)
    stringed_value = object.join(' , ')

    statement = RDF::Statement(
      subject: subject,
      predicate: rdf_predicate,
      object: stringed_value
    )

    @graph << statement unless statement.nil?
  end

  # Copied from /app/controllers/downloads_controller.rb
  def load_and_authorize_file
    @file = ActiveStorage::Attachment.find_by(fileset_uuid: params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file.record_id == params[:id]

    authorize @file, :download_file?
  end

end
