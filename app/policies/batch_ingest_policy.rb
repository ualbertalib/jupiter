class BatchIngestPolicy < ApplicationPolicy

  def permitted_attributes
    [:title, :spreadsheet_id, :spreadsheet_name, { file_ids: [], file_names: [] }]
  end

end
