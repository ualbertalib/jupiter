class DraftItemPolicy < ApplicationPolicy

  def show?
    owned? || admin?
  end

  def create?
    owned? || admin?
  end

  def update?
    create?
  end

  def set_thumbnail?
    create?
  end

  def file_create?
    create?
  end

  def file_destroy?
    create?
  end

  def owned?
    record && user && record.user.id == user.id
  end

  def permitted_attributes
    [:title, :alternate_title, :type_id,
     :date_created, :description,
     :source, :related_item,
     :license, :license_text_area, :visibility, :embargo_end_date,
     :status, :wizard_step,
     language_ids: [], creators: [], subjects: [],
     contributors: [], places: [], time_periods: [], citations: []]
  end

end
