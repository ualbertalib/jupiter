class DraftItem < ApplicationRecord

  enum status: { inactive: 0, active: 1, archived: 2 }
  enum wizard_step: { describe_item: 0, choose_license_and_visibility: 1, upload_files: 2, review_and_deposit_item: 3 }

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

  # Rails 5 turns presence check on by default for belongs_to relationships
  belongs_to :type, optional: true
  belongs_to :user

  validates :title, :type, :languages,
            :creators, :subjects, :date_created,
            :description, :community_and_collections,
            presence: true, if: :describe_item?

  validates :license, :visibility, presence: true, if: :choose_license_and_visibility?

  validates :files, presence: true, if: :upload_files?

  private

  def describe_item?
    active? && describe_item?
  end

  def choose_license_and_visibility?
    active? && choose_license_and_visibility?
  end

  def upload_files?
    active? && upload_files?
  end
end
