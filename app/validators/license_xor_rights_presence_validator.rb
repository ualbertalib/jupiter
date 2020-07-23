class LicenseXorRightsPresenceValidator < ActiveModel::Validator

  def validate(record)
    # Must have one of license or rights, not both
    if record.license.blank?
      record.errors.add(:base, :need_either_license_or_rights) if record.rights.blank?
    elsif record.rights.present?
      record.errors.add(:base, :not_both_license_and_rights)
    end
  end

end
