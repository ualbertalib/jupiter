class Digitization::Book < ApplicationRecord

  validates :peel_id, uniqueness: { scope: [:run, :part_number] }, presence: true, if: :part_number?
  validates :part_number, presence: true, if: :run?

  validates :temporal_subject, presence: true, unless: :geographic_subject? || :topical_subject?
  validates :geographic_subject, presence: true, unless: :temporal_subject? || :topical_subject?
  validates :topical_subject, presence: true, unless: :temporal_subject? || :geographic_subject?

  validates :title, presence: true
  validates :resource_type, presence: true, uri: { namespace: :digitization, in_vocabulary: :resource_type }
  validates :genre, presence: true, uri: { namespace: :digitization, in_vocabulary: :genre }
  validates :language, presence: true, uri: { namespace: :digitization, in_vocabulary: :language }
  validates :rights, presence: true, uri: { namespace: :digitization, in_vocabulary: :rights }

  validates :date_issued, edtf: true
  validates :temporal_subject, edtf: true

end
