class Digitization::BatchArtifactSetupIngest < ApplicationRecord

  enum status: { created: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user

  has_many :processing, dependent: :nullify, class_name: 'Digitization::Book',
                        foreign_key: :digitization_batch_artifact_setup_ingests_id,
                        inverse_of: false
  has_many :completed, dependent: :nullify, class_name: 'Digitization::Book',
                       foreign_key: :digitization_batch_artifact_setup_ingests_id,
                       inverse_of: false
  has_many :failed, dependent: :nullify, class_name: 'Digitization::Book',
                    foreign_key: :digitization_batch_artifact_setup_ingests_id,
                    inverse_of: false

  has_one_attached :csvfile

  validates :csvfile, presence: true
  validate :spreadsheet_has_required_data

  def spreadsheet_has_required_data
    return unless csvfile.attached? && attachment_changes['csvfile']

    CSV.foreach(attachment_changes['csvfile'].attachable[:io].path, headers: true) do |row|
      # Check if required fields are filled out
      if row['Code'].blank?
        errors.add(:csvfile,
                   "Local Identifier (Code) not found for row #{$INPUT_LINE_NUMBER} of spreadsheet")
      end
      errors.add(:csvfile, "Noid not found for row #{$INPUT_LINE_NUMBER} of spreadsheet") if row['Noid'].blank?
    end
  end

  def processing!(book)
    update(status: :processing) if failed.blank?
    processing << book
  end

  def completed!(book)
    processing.delete book
    completed << book
    update(status: :completed) if processing.empty? && failed.empty?
  end

  def failed!(book)
    update(status: :failed)
    processing.delete book
    failed << book
  end

end
