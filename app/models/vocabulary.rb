require 'linkeddata'

class Vocabulary < ApplicationRecord

  validates :uri, uniqueness: { scope: [:namespace, :vocab] }
  validates :code, uniqueness: { scope: [:namespace, :vocab] }

  scope :namespace, ->(namespace) { where(namespace: namespace) }
  scope :vocab, ->(vocab) { where(vocab: vocab) }
  scope :from_uri, ->(uri) { find_by(uri: uri).code }
  scope :code, ->(code) { find_by(code: code).uri }

  before_create do
    graph = RDF::Graph.load(uri)
    value = graph.query({ predicate: RDF::Vocab::SKOS.prefLabel }).first.object.to_s
    @code = value.parameterize.underscore
    Translation.create(locale: 'en', key: "vocabulary.#{namespace}.#{vocab}.#{code}", value: value)
  end

end
