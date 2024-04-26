class BatchIngestSpreadsheetValidator < ActiveModel::EachValidator

  # This Validator will validate if a given google spreadsheet id has all
  #  the required data needed to be successfully batch ingested
  def validate_each(record, attribute, value)
    return if value.blank?

    google_credentials = GoogleDriveClientService.new(
      access_token: record.access_token,
      refresh_token: record.refresh_token,
      expires_in: record.expires_in,
      issued_at: record.issued_at
    )

    google_spreadsheet = google_credentials.download_spreadsheet(value)
    google_file_names = record.batch_ingest_files.map(&:google_file_name)
    verified_google_file_names = {}

    google_spreadsheet.each_with_index do |row, index|
      row_number = index + 1

      # Check if required fields are filled out
      required_columns = [
        'file_name', 'title', 'item_type', 'languages', 'creators',
        'subject', 'created', 'community_id', 'collection_id',
        'license', 'visibility'
      ]

      required_columns.each do |column|
        record.errors.add(attribute, :missing_required_column, column:, row_number:) if row[column].blank?
      end

      # Check if "item_type" is article, then it must have a "publication_status"
      if row['item_type'] == 'article' && row['publication_status'].blank?
        record.errors.add(attribute, :publication_status_required_for_articles, row_number:)
      end

      # check if "status" is embargo, then it must have "embargo_end_date" and "visibility_after_embargo"
      if row['visibility'] == 'embargo' &&
         (row['embargo_end_date'].blank? || row['visibility_after_embargo'].blank?)
        record.errors.add(attribute, :embargo_missing_required_data, row_number:)
      end

      # Check if given community/collection ids actually exists?
      unless Community.exists?(row['community_id'])
        record.errors.add(attribute, :column_not_found, column: 'community_id', row_number:)
      end

      unless Collection.exists?(row['collection_id'])
        record.errors.add(attribute, :column_not_found, column: 'collection_id', row_number:)
      end

      # Confirm metadata matches vocab when required.
      begin
        ControlledVocabulary.era.item_type.send(row['item_type'].to_sym) if row['item_type'].present?

        if row['languages'].present?
          row['languages'].split('|').map(&:strip).map do |language|
            ControlledVocabulary.era.language.send(language.to_sym) if language.present?
          end
        end

        ControlledVocabulary.jupiter_core.visibility.send(row['visibility'].to_sym) if row['visibility'].present?

        if row['visibility_after_embargo'].present?
          ControlledVocabulary.jupiter_core.visibility.send(row['visibility_after_embargo'].to_sym)
        end
      rescue JupiterCore::VocabularyMissingError => e
        record.errors.add(attribute, :invalid_metadata, exception_message: e.message, row_number:)
      end

      # Ensure that all files name in the spreadsheet have a corresponding uploaded file

      file_names = row['file_name'].split('|').map(&:strip)
      missing_files = file_names - google_file_names

      unless missing_files.empty?
        record.errors.add(attribute, :no_matching_files, file_names: missing_files.join(', '),
                                                         row_number:)
      end

      # Keep a log of the files that have been listed for all items
      file_names.each do |file_name|
        verified_google_file_names[file_name] = [] unless verified_google_file_names.key?(file_name)
        verified_google_file_names[file_name] << row_number
      end
    end

    # Ensure files in spreadsheet are only used once for all uploaded files
    verified_google_file_names.each do |file_name, rows|
      record.errors.add(attribute, :duplicate_files, file_name:, rows: rows.join(', ')) if rows.many?
    end
  rescue StandardError
    # Most likely `download_spreadsheet` method threw an error as given spreadsheet doesn't match what we expected
    record.errors.add(attribute, :spreadsheet_could_not_be_read)
  end

end
