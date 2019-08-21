class ItemDoiState < ApplicationRecord

  include AASM

  validates :item_id, presence: true
  validates :aasm_state, presence: true

  aasm do
    state :not_available, initial: true
    state :unminted
    state :excluded
    state :available
    state :awaiting_update

    event :created, after: :queue_create_job do
      transitions from: :not_available, to: :unminted
    end

    event :removed, after: :withdraw_doi do
      transitions from: [:available, :not_available], to: :excluded
    end

    event :unpublish do
      transitions from: [:excluded, :awaiting_update, :unminted], to: :not_available
    end

    event :synced do
      transitions from: [:unminted, :awaiting_update], to: :available
    end

    event :altered, after: :queue_update_job do
      transitions from: [:available, :not_available], to: :awaiting_update
    end
  end

  def item
    begin
      Item.find(item_id)
    rescue ActiveRecord::RecordNotFound
      Thesis.find(item_id)
    end
  end

  def withdraw_doi
    DOIRemoveJob.perform_later(item.doi) if item.doi.present?
  end

  def doi_fields_changed?(unlocked_item)
    unlocked_item.changed.any? do |changed_field|
      ['title', 'creator', 'dissertant', 'item_type', 'publication_status'].include? changed_field
    end
  end

  def queue_create_job
    DOICreateJob.perform_later(item.id)
  end

  def queue_update_job
    DOIUpdateJob.perform_later(item.id)
  end

end
