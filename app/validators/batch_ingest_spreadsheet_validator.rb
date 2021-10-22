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

    google_spreadsheet.each_with_index do |row, index|
      row_number = index + 1

      # Check if required fields are filled out
      required_columns = [
        'file_name', 'title', 'type', 'owner_id',
        'languages', 'creators', 'subjects', 'date_created',
        'community_id', 'collection_id', 'license', 'visibility'
      ]

      required_columns.each do |column|
        if row[column].blank?
          record.errors.add(attribute, :missing_required_column, column: column, row_number: row_number)
        end
      end

      # Check if "type" is article, then it must have a "publication_status"
      if row['type'] == 'article' && row['publication_status'].blank?
        record.errors.add(attribute, :publication_status_required_for_articles, row_number: row_number)
      end

      # check if "status" is embargo, then it must have "embargo_end_date" and "visibility_after_embargo"
      if row['visibility'] == 'embargo' &&
         (row['embargo_end_date'].blank? || row['visibility_after_embargo'].blank?)
        record.errors.add(attribute, :embargo_missing_required_data, row_number: row_number)
      end

      # Check if given owner/community/collection ids actually exists?
      unless Community.exists?(row['community_id'])
        record.errors.add(attribute, :column_not_found, column: 'community_id', row_number: row_number)
      end

      unless Collection.exists?(row['collection_id'])
        record.errors.add(attribute, :column_not_found, column: 'collection_id', row_number: row_number)
      end

      unless User.exists?(row['owner_id'])
        record.errors.add(attribute, :column_not_found, column: 'owner_id', row_number: row_number)
      end

      # Ensure that any file name in the spreadsheet has an corresponding file
      unless record.batch_ingest_files.any? { |file| row['file_name'] == file.google_file_name }
        record.errors.add(attribute, :no_matching_files, row_number: row_number)
      end
    end
  rescue StandardError
    # Most likely `download_spreadsheet` method threw an error as given spreadsheet doesn't match what we expected
    record.errors.add(attribute, :spreadsheet_could_not_be_read)
  end

end
