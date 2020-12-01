class BatchIngestPolicy < ApplicationPolicy

  def permitted_attributes
    [:title]
  end

end
