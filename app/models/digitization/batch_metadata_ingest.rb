class Digitization::BatchMetadataIngest < ApplicationRecord

  enum status: { created: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user

  has_many :books, dependent: :nullify, class_name: 'Digitization::Book',
                   foreign_key: :digitization_batch_metadata_ingest_id,
                   inverse_of: :digitization_batch_metadata_ingest
  has_one_attached :csvfile

  validates :csvfile, presence: true, digitization_batch_metadata_ingest_csvfile: true
  validates :title, presence: true

end
