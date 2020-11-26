class Digitization::Book < ApplicationRecord

  validates :peel_id, uniqueness: { scope: [:run, :part_number] }
  validates :part_number, presence: true, if: :run?

end
