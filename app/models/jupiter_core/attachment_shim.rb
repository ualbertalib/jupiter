class JupiterCore::AttachmentShim < ApplicationRecord

  has_one_attached :shimmed_file, dependent: false
  has_many_attached :shimmed_files, dependent: false

  def logo_file
    shimmed_files.find_by(id: logo_id)
  end

  def owner
    GlobalID::Locator.locate(owner_global_id)
  end

end
