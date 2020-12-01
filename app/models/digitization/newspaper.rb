class Digitization::Newspaper < ApplicationRecord

  validates :publication_code, uniqueness: { scope: [:year, :month, :day] }
  validates :year, :month, :day, presence: true, if: :publication_code?

end
