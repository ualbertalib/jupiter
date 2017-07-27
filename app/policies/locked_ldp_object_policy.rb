# Special policy for LockedLdpObjects to inherit from
class LockedLdpObjectPolicy < ApplicationPolicy

  def permitted_attributes
    model_class.safe_attributes
  end

  protected

  def model_class
    record.is_a?(Class) ? record : record.class
  end

end
