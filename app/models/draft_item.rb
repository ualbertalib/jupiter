class DraftItem < ApplicationRecord

  has_and_belongs_to_many :languages
  has_and_belongs_to_many :creators
  has_and_belongs_to_many :subjects
  has_and_belongs_to_many :community_and_collections
  has_and_belongs_to_many :contributors
  has_and_belongs_to_many :places
  has_and_belongs_to_many :time_periods
  has_and_belongs_to_many :citations

  belongs_to :type
  belongs_to :user

end
