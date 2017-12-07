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

  def owned?
    record && user && record.user.id == user.id
  end

  def permitted_attributes
    [:title, :alternate_title, :type_id,
     :date_created, :description,
     :source, :related_item,
     :license, :license_text_area, :visibility, :embargo_date,
     :status, :wizard_step,
     language_ids: [], creators_ids: [], subject_ids: [],
     contributor_ids: [], place_ids: [], time_period_ids: [], citation_ids: []]
  end

end
