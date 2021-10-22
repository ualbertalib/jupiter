class Digitization::Newspaper < JupiterCore::Depositable

  belongs_to :owner, class_name: 'User'

  validates :publication_code, uniqueness: { scope: [:year, :month, :day] }
  validates :year, :month, :day, presence: true, if: :publication_code?

end
