class ReadOnlyMode < ApplicationRecord

  validate :only_one_record_exists, on: :create
  validates :enabled, inclusion: { in: [true, false] }

  private

  def only_one_record_exists
    errors.add(:enabled, :only_one_record_exists) if ReadOnlyMode.count > 0
  end

end
