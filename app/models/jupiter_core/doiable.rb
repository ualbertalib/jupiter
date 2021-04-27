class JupiterCore::Doiable < JupiterCore::Depositable

  self.abstract_class = true

  include AASM

  attr_accessor :skip_handle_doi_states

  before_save :handle_doi_states
  after_create :handle_doi_states
  before_destroy :remove_doi

  aasm do
    state :not_available, initial: true
    state :unminted
    state :excluded
    state :available
    state :awaiting_update

    event :initially_created, after: :queue_create_job do
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

  def doi_url
    "https://doi.org/#{doi.delete_prefix('doi:')}"
  end

  def handle_doi_states
    # this should be disabled during migration runs and enabled for production
    return unless Rails.application.secrets.doi_minting_enabled

    return if id.blank?

    # Allow this logic to be skipped if skip_handle_doi_states is set.
    # This is mainly used so we can rollback the state when a job fails and
    # we do not wish to rerun all this logic again which would queue up the same job again
    return (self.skip_handle_doi_states = false) if skip_handle_doi_states.present?

    if doi.blank? # Never been minted before
      initially_created!(id) if !private? && not_available?
    elsif (not_available? && transitioned_from_private?) ||
          (available? && (doi_fields_changed? || transitioned_to_private?))
      # If private, we only care if visibility has been made public
      # If public, we care if visibility changed to private or doi fields have been changed
      altered!(id)
    end
  end

  def remove_doi
    removed! if doi.present? && (available? || not_available?)
  end

  # for use when deleting items for later re-migration, to avoid tombstoning
  # manually updates the underlying aasm_state to preclude running the Withdrawl job
  # rubocop:disable Rails/SkipsModelValidations
  def doi_safe_destroy!
    update_attribute(:aasm_state, 'excluded')
    destroy!
  end
  # rubocop:enable Rails/SkipsModelValidations

  def withdraw_doi
    DOIRemoveJob.perform_later(doi) if doi.present?
  end

  DOI_FIELDS = ['title', 'creator', 'dissertant', 'item_type', 'publication_status'].freeze
  def doi_fields_changed?
    changed.any? do |changed_field|
      DOI_FIELDS.include? changed_field
    end
  end

  def queue_create_job
    DOICreateJob.perform_later(id)
  end

  def queue_update_job
    DOIUpdateJob.perform_later(id)
  end

end
