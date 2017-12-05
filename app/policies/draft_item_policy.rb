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
    [:title, :alternate_title, :date_created, :description, :source,
     :related_item, :license, :license_text_area, :visibility,
     :embargo_date, :type_id]
  end

end
