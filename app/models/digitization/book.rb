class Digitization::Book < JupiterCore::Depositable

  acts_as_rdfable

  belongs_to :digitization_batch_metadata_ingest, optional: true

  has_one_attached :historical_archive
  has_one :fulltext, dependent: :destroy, class_name: 'Digitization::Fulltext', inverse_of: :book,
                     foreign_key: :digitization_book_id

  has_solr_exporter Exporters::Solr::Digitization::BookExporter

  belongs_to :owner, class_name: 'User'

  has_many_attached :files, dependent: false

  has_paper_trail

  validates :peel_id, uniqueness: { scope: [:run, :part_number] }, presence: true, if: :part_number?
  validates :part_number, presence: true, if: :run?

  validates :temporal_subjects, presence: true, unless: :geographic_subjects? || :topical_subjects?
  validates :geographic_subjects, presence: true, unless: :temporal_subjects? || :topical_subjects?
  validates :topical_subjects, presence: true, unless: :temporal_subjects? || :geographic_subjects?

  validates :title, presence: true
  validates :resource_type, presence: true, uri: { namespace: :digitization, in_vocabulary: :resource_type }
  validates :genres, presence: true, uri: { namespace: :digitization, in_vocabulary: :genre }
  validates :languages, presence: true, uri: { namespace: :digitization, in_vocabulary: :language }
  validates :rights, presence: true, uri: { namespace: :digitization, in_vocabulary: :rights }

  validates :dates_issued, edtf: true
  validates :temporal_subjects, edtf: true

  def all_subjects
    topical_subjects + temporal_subjects.to_a + geographic_subjects.to_a
  end

  def all_contributors
    publishers
  end

  def hydra_noid
    # TODO: this is required by Exporters::Solr::BaseExporter but doesn't apply to digitization
    nil
  end

end
