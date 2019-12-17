require 'rdf/n3'
require 'rdf/vocab'
import RDF 

class Aip::V1::ItemsController < ApplicationController

  before_action :load_item, only: [:show]

  def show
    authorize @item
    graph = RDF::Graph.new

    @item.rdf_annotations.each do |rdf_annotation|
      column = rdf_annotation.column
      value = @item.send(column)
      # binding.pry
      next if value.nil?
      value = [value] unless value.kind_of?(Array)
      
      predicate = RDF::Vocabulary::Term.new(rdf_annotation.predicate)

      stringed_value = value.join(' , ')

      statement = RDF::Statement(
        subject: subject,
        predicate: predicate,
        object: stringed_value
      )
      graph << statement

    end

    triples = graph.dump(:n3)
    render plain: triples, status: :ok
  end

  private

  def load_item
    @item = Item.find(params[:id])
  end

end
