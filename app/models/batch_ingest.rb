class BatchIngest < ApplicationRecord

  enum status: { created: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user

  has_many :items, dependent: :nullify
  has_many :batch_ingest_files, dependent: :destroy

  accepts_nested_attributes_for :batch_ingest_files

  validates :access_token, presence: true
  validates :google_spreadsheet_id, presence: true
  validates :google_spreadsheet_id, batch_ingest_spreadsheet: true, on: :create
  validates :google_spreadsheet_name, presence: true
  validates :batch_ingest_files, presence: true, length: { maximum: 50 }
  validates :title, presence: true, uniqueness: { case_sensitive: false }

end
