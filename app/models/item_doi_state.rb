class ItemDoiState < ApplicationRecord
  include AASM

  validates_presence_of :item_id
  validates_presence_of :aasm_state

  aasm do
    state :not_available, initial: true
    state :unminted
    state :excluded
    state :available
    state :awaiting_update

    event :created, after: :queue_create_job do
     transitions from: :not_available, to: :unminted
    end

    event :removed do
     transitions from: :not_available, to: :excluded
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
    JupiterCore::LockedLdpObject.find(item_id, types: [Item, Thesis])
  end

  def doi_fields_present?
    # TODO: Shouldn't have to do this as these are required fields on the UI.
    # However since no data integrity a GF without these fields is technically valid... have to double check
    # item.title.present? && (item.creator.present? || item.dissertant.present?) &&
    #   resource_type.present? && Sufia.config.admin_resource_types[resource_type.first].present?
  end

  private

  def withdraw_doi
    DOIRemoveJob.perform_later(doi) if doi.present?
  end

  def handle_doi_states
    # ActiveFedora doesn't have skip_callbacks built in? So handle this ourselves.
    # Allow this logic to be skipped if skip_handle_doi_states is set.
    # This is mainly used so we can rollback the state when a job fails and
    # we do not wish to rerun all this logic again which would queue up the same job again
    if skip_handle_doi_states.blank?
      return if !doi_fields_present?

      if doi.blank? # Never been minted before
        created!(id) if !private? && not_available?
      else
        # If private, we only care if visibility has been made public
        # If public, we care if visibility changed to private or doi fields have been changed
        if (not_available? && transitioned_from_private?) ||
         (available? && (doi_fields_changed? || transitioned_to_private?))
         altered!(id)
        end
      end
    else
      # Return it back to false, so callback can run on the next save
      self.skip_handle_doi_states = false
    end
  end

  def doi_fields_changed?
    # [:title, :creator, :year_created, :resource_type].any? do |k|
    #   # check if the changes are actually different
    #   return true if previous_changes[k][0] != previous_changes[k][1] if previous_changes.key?(k)
    # end
    # false
  end

  def queue_create_job()
    DOICreateJob.perform_later()
  end

  def queue_update_job()
    DOIUpdateJob.perform_later()
  end
end
