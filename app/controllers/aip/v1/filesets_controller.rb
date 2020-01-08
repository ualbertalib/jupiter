require 'rdf/n3'
require 'rdf/vocab'
import RDF

class Aip::V1::FilesetsController < ApplicationController

  before_action :load_fileset, only: [:show]

  def show
    @graph = RDF::Graph.new

    # Add nodes here

    triples = @graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def load_item
    @fileset = Item.find(params[:id])
  end

end
