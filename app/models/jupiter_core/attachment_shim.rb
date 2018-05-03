class JupiterCore::AttachmentShim < ApplicationRecord

  has_one_attached :shimmed_file, dependent: :purge_later
  has_many_attached :shimmed_files, dependent: :purge_later

end
