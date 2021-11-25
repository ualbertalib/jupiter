class Digitization::BatchArtifactIngest < ApplicationRecord

  belongs_to :user

  has_many :processing_books, -> { where(batch_ingest_status: :processing) },
           dependent: :nullify, class_name: 'Digitization::Book',
           foreign_key: :digitization_batch_artifact_ingests_id,
           inverse_of: false
  has_many :completed_books, -> { where(batch_ingest_status: :completed) },
           dependent: :nullify, class_name: 'Digitization::Book',
           foreign_key: :digitization_batch_artifact_ingests_id,
           inverse_of: false
  has_many :failed_books, -> { where(batch_ingest_status: :failed) },
           dependent: :nullify, class_name: 'Digitization::Book',
           foreign_key: :digitization_batch_artifact_ingests_id,
           inverse_of: false

  has_one_attached :csvfile

  validates :csvfile, presence: true
  validate :spreadsheet_has_required_data

  def spreadsheet_has_required_data
    return unless csvfile.attached? && attachment_changes['csvfile']

    CSV.foreach(attachment_changes['csvfile'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      ['Code', 'Noid'].each do |required_column|
        if row[required_column].blank?
          errors.add(:csvfile, :missing_required_column, column: required_column,
                                                         row_number: $INPUT_LINE_NUMBER)
        end
      end
    end
  end

  def completed?
    processing_books.count == 0 && failed_books.count == 0
  end

  def failed?
    failed_books.count
  end

end
