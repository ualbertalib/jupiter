class DraftItemPolicy < ApplicationPolicy

  def show?
    create?
  end

  def create?
    (owned? && unrestricted_collections?) || admin?
  end

  def update?
    create?
  end

  def destroy?
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

  def thumbnail?
    true
  end

  def owned?
    record && user && record.user.id == user.id
  end

  def unrestricted_collections?
    record.each_community_collection do |_community, collection|
      return false if collection.restricted
    end
    true
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
