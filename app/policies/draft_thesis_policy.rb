class DraftThesisPolicy < ApplicationPolicy

  def thumbnail?
    true
  end

  def permitted_attributes
    [:title, :alternate_title, :creator, :language_id,
     :graduation_term, :graduation_year, :description,
     :rights, :visibility, :embargo_end_date,
     :status, :wizard_step, :date_accepted, :date_submitted,
     :degree, :degree_level, :institution_id, :specialization,
     subjects: [], supervisors: [], departments: [], committee_members: []]
  end

end
