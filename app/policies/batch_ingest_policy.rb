class BatchIngestPolicy < ApplicationPolicy

  def permitted_attributes
    [:title,
     :google_spreadsheet_id,
     :google_spreadsheet_name,
     { batch_ingest_files_attributes: [:google_file_id, :google_file_name] }]
  end

end
