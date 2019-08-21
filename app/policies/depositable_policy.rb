# Special policy for LockedLdpObjects to inherit from
class DepositablePolicy < ApplicationPolicy

  def permitted_attributes
    model_class.safe_attributes
  end

  protected

  def model_class
    record.is_a?(Class) ? record : record.class
  end

  def owned?
    return false unless user_is_authenticated?

    record.owner_id == user.id
  end

  def public?
    record.public?
  end

  def record_requires_authentication?
    record.authenticated?
  end

  def user_is_authenticated?
    user.present? && user.id.present?
  end

  def user_is_authenticated_for_record?
    user_is_authenticated? && record_requires_authentication?
  end

end
