class BatchIngest < ApplicationRecord

  enum status: { created: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :user

  has_many :items, dependent: :nullify
  has_many :batch_ingest_files, dependent: :destroy

  accepts_nested_attributes_for :batch_ingest_files

  validates :access_token, presence: true
  validates :google_spreadsheet_id, presence: true
  validates :google_spreadsheet_name, presence: true
  validates :batch_ingest_files, presence: true
  validates :title, presence: true, uniqueness: { case_sensitive: false }

  validate :spreadsheet_has_required_data, on: :create

  # TODO: Enhance validations? Check if File matches file selected? Move to validator class?
  def spreadsheet_has_required_data
    return if google_spreadsheet_id.blank?

    google_credentials = GoogleDriveClientService.new(
      access_token: access_token,
      refresh_token: refresh_token,
      expires_in: expires_in,
      issued_at: issued_at
    )

    google_spreadsheet = google_credentials.download_spreadsheet(google_spreadsheet_id)

    google_spreadsheet.each_with_index do |row, index|
      row_number = index + 1

      # Check if required fields are filled out
      errors.add(:spreadsheet, "file_name not found for row #{row_number} of spreadsheet") if row['file_name'].blank?
      errors.add(:spreadsheet, "title not found for row #{row_number} of spreadsheet") if row['title'].blank?
      errors.add(:spreadsheet, "type not found for row #{row_number} of spreadsheet") if row['type'].blank?
      errors.add(:spreadsheet, "owner_id not found for row #{row_number} of spreadsheet") if row['owner_id'].blank?
      errors.add(:spreadsheet, "languages not found for row #{row_number} of spreadsheet") if row['languages'].blank?
      errors.add(:spreadsheet, "creators not found for row #{row_number} of spreadsheet") if row['creators'].blank?
      errors.add(:spreadsheet, "subjects not found for row #{row_number} of spreadsheet") if row['subjects'].blank?
      if row['date_created'].blank?
        errors.add(:spreadsheet,
                   "date_created not found for row #{row_number} of spreadsheet")
      end
      if row['community_id'].blank?
        errors.add(:spreadsheet,
                   "community_id not found for row #{row_number} of spreadsheet")
      end
      if row['collection_id'].blank?
        errors.add(:spreadsheet,
                   "collection_id not found for row #{row_number} of spreadsheet")
      end
      errors.add(:spreadsheet, "license not found for row #{row_number} of spreadsheet") if row['license'].blank?
      errors.add(:spreadsheet, "visibility not found for row #{row_number} of spreadsheet") if row['visibility'].blank?

      # Check if given owner/community/collection ids actually exists?
      unless Community.exists?(row['community_id'])
        errors.add(:spreadsheet,
                   "community_id does not exist in ERA for row #{row_number} of spreadsheet")
      end
      unless Collection.exists?(row['collection_id'])
        errors.add(:spreadsheet,
                   "collection_id does not exist in ERA for row #{row_number} of spreadsheet")
      end
      unless User.exists?(row['owner_id'])
        errors.add(:spreadsheet,
                   "owner_id does not exist in ERA for row #{row_number} of spreadsheet")
      end

      # Ensure that any file name in the spreadsheet has corresponding batch ingest file
      unless batch_ingest_files.any? { |file| row['file_name'] == file.google_file_name }
        errors.add(:spreadsheet,
                   "file_name for row #{row_number} of spreadsheet does not match any of the selected files")
      end
    end
  end

end
