require 'rdf/n3'
require 'rdf/vocab'
import RDF

class Aip::V1::ItemsController < ApplicationController

  before_action :load_item, only: [:show, :file_sets]

  def show
    authorize @item
    @graph = RDF::Graph.new
    subject = RDF::URI(request.url)

    @item.rdf_annotations.each do |rdf_annotation|
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
      fileset_url = request.original_url + "/filesets/#{file.fileset_uuid}"
      add_statement!(
        subject: subject,
        predicate: CONTROLLED_VOCABULARIES[:pcdm].has_member,
        object: fileset_url
      )
    end

    # Add owners email seperatedly because is a relation with 2 steps in
    # distance

    owners_email = @item.owner.email

    add_statement!(
      subject: subject,
      predicate: RDF::Vocab::BIBO.owner,
      object: owners_email
    )

    triples = @graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def file_sets
    authorize @item

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.file_order do
        @item.files.each do |file|
          xml.uuid_ file.fileset_uuid
        end
      end
    end
    render xml: builder.to_xml
  end

  private

  def load_item
    @item = Item.find(params[:id])
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

end
