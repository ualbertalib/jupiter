class BatchIngestFile < ApplicationRecord

  belongs_to :batch_ingest

  validates :google_file_id, presence: true
  validates :google_file_name, presence: true

end
