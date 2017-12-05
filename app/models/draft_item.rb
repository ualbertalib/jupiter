class DraftItem < ApplicationRecord

  has_many :draft_items_languages, dependent: :destroy
  has_many :draft_items_creators, dependent: :destroy
  has_many :draft_items_subjects, dependent: :destroy
  has_many :draft_items_community_and_collections, dependent: :destroy
  has_many :draft_items_contributors, dependent: :destroy
  has_many :draft_items_place, dependent: :destroy
  has_many :draft_items_time_period, dependent: :destroy
  has_many :draft_items_citation, dependent: :destroy

  has_many :languages, through: :draft_items_languages
  has_many :creators, through: :draft_items_creators
  has_many :subjects, through: :draft_items_subjects
  has_many :community_and_collections, through: :draft_items_community_and_collections
  has_many :contributors, through: :draft_items_contributors
  has_many :places, through: :draft_items_place
  has_many :time_periods, through: :draft_items_time_period
  has_many :citations, through: :draft_items_citation

  belongs_to :type
  belongs_to :user

end
