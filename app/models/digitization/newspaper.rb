class Digitization::Newspaper < JupiterCore::Depositable

  acts_as_rdfable

  belongs_to :owner, class_name: 'User'

  has_solr_exporter Exporters::Solr::Digitization::BookExporter

  validates :publication_code, uniqueness: { scope: [:year, :month, :day] }
  validates :year, :month, :day, presence: true, if: :publication_code?

  validates :geographic_subjects, presence: true
  validates :resource_type, presence: true, uri: { namespace: :digitization, in_vocabulary: :resource_type }
  validates :genres, presence: true, uri: { namespace: :digitization, in_vocabulary: :genre }
  validates :languages, presence: true, uri: { namespace: :digitization, in_vocabulary: :language }
  validates :rights, presence: true, uri: { namespace: :digitization, in_vocabulary: :rights }

  validates :dates_issued, edtf: true

end
