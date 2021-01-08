class Digitization::Book < ApplicationRecord

  validates :peel_id, uniqueness: { scope: [:run, :part_number] }, presence: true, if: :part_number?
  validates :part_number, presence: true, if: :run?

  validates :temporal_subject, presence: true, unless: :geographic_subject? || :topical_subject?
  validates :geographic_subject, presence: true, unless: :temporal_subject? || :topical_subject?
  validates :topical_subject, presence: true, unless: :temporal_subject? || :geographic_subject?

  validates :title, presence: true
  validates :resource_type, presence: true, uri: { in_vocabulary: :digitization_resource_type }
  validates :genre, presence: true, uri: { in_vocabulary: :digitization_genre }
  validates :language, presence: true, uri: { in_vocabulary: :digitization_language }
  validates :rights, presence: true, uri: { in_vocabulary: :digitization_rights } 

end
