class JupiterCore::Depositable < ApplicationRecord

  self.abstract_class = true

  VISIBILITY_EMBARGO = CONTROLLED_VOCABULARIES[:visibility].embargo.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze
  VISIBILITIES_AFTER_EMBARGO = [CONTROLLED_VOCABULARIES[:visibility].authenticated,
                                CONTROLLED_VOCABULARIES[:visibility].draft,
                                CONTROLLED_VOCABULARIES[:visibility].public].freeze

  validate :visibility_must_be_known
  validates :owner_id, presence: true
  validates :record_created_at, presence: true
  validates :date_ingested, presence: true
  validates :title, presence: true

  before_validation :set_record_created_at, on: :create
  before_validation :set_date_ingested

  # this isn't a predicate name you daft thing
  # rubocop:disable Naming/PredicateName
  def self.has_solr_exporter(klass)
    class << self

      attr_accessor :solr_exporter_class

    end
    define_method :solr_exporter do
      return solr_exporter_class.new(self)
    end
    define_method :solr_exporter_class do
      return self.class.solr_exporter_class
    end

    self.solr_exporter_class = klass

    after_save :update_solr

    # Note the ordering here: we remove it from solr _before_ destroying it, so that
    # queries happining around the time of the deletion in Postgres don't get results that crash the page
    # when the ID that came back from Solr is no longer in Postgres.
    before_destroy :remove_from_solr

    # TODO
    # update on a rollback if the model is persisted after the rollback, because in some cases like a rolled-back
    # destroy, the record may no longer be in Solr even though it still exists in Postgres
    #  after_rollback :remove_from_solr
  end
  # rubocop:enable Naming/PredicateName

  def update_solr
    solr_doc = solr_exporter.export
    JupiterCore::SolrServices::Client.instance.add_or_update_document(solr_doc)
  end

  def remove_from_solr
    JupiterCore::SolrServices::Client.instance.remove_document(id)
  end

  def self.valid_visibilities
    [JupiterCore::VISIBILITY_PUBLIC, JupiterCore::VISIBILITY_PRIVATE, JupiterCore::VISIBILITY_AUTHENTICATED]
  end

  def public?
    visibility == JupiterCore::VISIBILITY_PUBLIC
  end

  def private?
    visibility == JupiterCore::VISIBILITY_PRIVATE
  end

  def authenticated?
    visibility == JupiterCore::VISIBILITY_AUTHENTICATED
  end

  def doi_url
    "https://doi.org/#{doi.gsub(/^doi\:/, '')}"
  end

  def each_community_collection
    member_of_paths.each do |path|
      community_id, collection_id = path.split('/')
      yield Community.find(community_id), Collection.find(collection_id)
    end
  end

  def authors
    respond_to?(:creators) ? creators : [dissertant]
  end

  def creation_date
    respond_to?(:created) ? created : graduation_date
  end

  def copyright
    respond_to?(:license) ? license : rights
  end

  # this method came with us from LockedLdpObject, and it'll keep this name until it gets refactored
  # rubocop:disable Naming/AccessorMethodName
  def set_thumbnail(attachment)
    self.logo_id = attachment.id
    save!
  end
  # rubocop:enable Naming/AccessorMethodName

  def thumbnail_url(args = { resize: '100x100', auto_orient: true })
    logo = files.find_by(id: logo_id)
    return nil if logo.blank?

    Rails.application.routes.url_helpers.rails_representation_path(logo.variant(args).processed)
  rescue ActiveStorage::InvariableError
    begin
      Rails.application.routes.url_helpers.rails_representation_path(logo.preview(args).processed)
    rescue ActiveStorage::UnpreviewableError
      nil
    end
  end

  def thumbnail_file
    files.find_by(id: logo_id)
  end

  def add_and_ingest_files(file_handles = [])
    return if file_handles.blank?
    raise 'Item not yet saved!' if id.nil?

    file_handles.each do |fileio|
      attached = files.attach(io: fileio, filename: File.basename(fileio.path))
      # TODO: Do something smarter here if not attached
      next unless attached

      attachment = files.attachments.last
      attachment.fileset_uuid = UUIDTools::UUID.random_create
      attachment.save!
    end
  end

  def set_record_created_at
    self.record_created_at = Time.current.utc.iso8601(3)
  end

  def set_date_ingested
    return if date_ingested.present?

    self.date_ingested = record_created_at
  end

  def visibility_must_be_known
    return true if visibility.present? && self.class.valid_visibilities.include?(visibility)

    errors.add(:visibility, I18n.t('locked_ldp_object.errors.invalid_visibility', visibility: visibility))
  end

  def communities_and_collections_must_exist
    return if member_of_paths.blank?

    member_of_paths.each do |path|
      community_id, collection_id = path.split('/')
      community = Community.find_by(id: community_id)
      errors.add(:member_of_paths, :community_not_found, id: community_id) if community.blank?
      collection = Collection.find_by(id: collection_id)
      errors.add(:member_of_paths, :collection_not_found, id: collection_id) if collection.blank?
    end
  end

  def visibility_after_embargo_must_be_valid
    return if visibility_after_embargo.nil?
    return if VISIBILITIES_AFTER_EMBARGO.include?(visibility_after_embargo)

    errors.add(:visibility_after_embargo, :not_recognized)
  end

  # utility methods for checking for certain visibility transitions
  def transitioned_to_private?
    return true if changes['visibility'].present? &&
                   (changes['visibility'][0] != JupiterCore::VISIBILITY_PRIVATE) &&
                   (changes['visibility'][1] == JupiterCore::VISIBILITY_PRIVATE)
  end

  def transitioned_from_private?
    return true if changes['visibility'].present? &&
                   (changes['visibility'][0] == JupiterCore::VISIBILITY_PRIVATE) &&
                   (changes['visibility'][1] != JupiterCore::VISIBILITY_PRIVATE)
  end

  def add_to_embargo_history
    self.embargo_history ||= []
    embargo_history_item = "An embargo was deactivated on #{Time.now.getlocal('-06:00')}. Its release date was " \
    "#{embargo_end_date}. Intended visibility after embargo was #{visibility_after_embargo}"
    self.embargo_history << embargo_history_item
  end

  def push_item_id_for_preservation
    if preserve == false
      Rails.logger.warn("Could not preserve #{id}")
      Rollbar.error("Could not preserve #{id}")
    end

    true
  rescue StandardError => e
    # we trap errors in writing to the Redis queue in order to avoid crashing the save process for the user.
    Rollbar.error("Error occured in push_item_id_for_preservation, Could not preserve #{id}", e)
    true
  end

  # rubocop:disable Style/GlobalVars
  def preserve
    queue_name = Rails.application.secrets.preservation_queue_name

    $queue ||= ConnectionPool.new(size: 1, timeout: 5) { Redis.current }

    $queue.with do |connection|
      connection.zadd queue_name, Time.now.to_f, id
    end

  # rescue all preservation errors so that the user can continue to use the application normally
  rescue StandardError => e
    Rollbar.error("Could not preserve #{id}", e)
  end
  # rubocop:enable Style/GlobalVars

  def to_partial_path
    self.class.to_s.downcase
  end

  def self.sort_order(params)
    if params.key? :sort
      { params[:sort] => params[:direction] }
    else
      solr_exporter_class.default_ar_sort_args
    end
  end

  def self.safe_attributes
    attribute_names.map(&:to_sym) - [:id]
  end

end
