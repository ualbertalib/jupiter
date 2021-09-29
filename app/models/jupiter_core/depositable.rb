class MissingImplementationError < StandardError; end

class JupiterCore::Depositable < ApplicationRecord

  self.abstract_class = true

  VISIBILITY_EMBARGO = ControlledVocabulary.jupiter_core.visibility.embargo.freeze
  VISIBILITIES = (JupiterCore::VISIBILITIES + [VISIBILITY_EMBARGO]).freeze
  VISIBILITIES_AFTER_EMBARGO = [ControlledVocabulary.jupiter_core.visibility.authenticated,
                                ControlledVocabulary.jupiter_core.visibility.draft,
                                ControlledVocabulary.jupiter_core.visibility.public].freeze

  validates :visibility, known_visibility: true

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

  def thumbnail_file
    files.find_by(id: logo_id)
  end

  def add_and_ingest_files(file_handles = [])
    return if file_handles.blank?
    raise 'Item not yet saved!' if id.nil?

    file_handles.each do |fileio|
      file_name = fileio.try(:original_filename) || File.basename(fileio.path)
      attached = files.attach(io: fileio, filename: file_name)
      # TODO: Do something smarter here if not attached
      next unless attached

      attachment = files.attachments.last
      attachment.fileset_uuid = UUIDTools::UUID.random_create
      attachment.save!
    end
  end

  def set_record_created_at
    return if record_created_at.present?

    self.record_created_at = Time.current.utc.iso8601(3)
  end

  def set_date_ingested
    return if date_ingested.present?

    self.date_ingested = record_created_at
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

  # rubocop:disable Style/GlobalVars

  def push_entity_for_preservation
    queue_name = Rails.application.secrets.preservation_queue_name

    $queue ||= ConnectionPool.new(size: 1, timeout: 5) { Redis.current }

    $queue.with do |connection|
      # pushmi_pullyu requires both the id and type of the depositable
      entity = { uuid: id, type: self.class.table_name }
      connection.zadd queue_name, Time.now.to_f, entity.to_json
    end

    true
  rescue StandardError => e
    # we trap errors in writing to the Redis queue in order to avoid crashing the save process for the user.
    Rollbar.error("Error occurred in push_entity_for_preservation, Could not preserve #{id}", e)
    true
  end
  # rubocop:enable Style/GlobalVars

  def to_partial_path
    self.class.name.demodulize.underscore
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

  # Since we need a generic way to specify the scope by which a model will eagerly fetch attachments,
  # and since the ActiveStorage auto-generated scopes "bake-in" the name of the eager-loading method
  # (eg, for +class Foo; has_one_attached :document; end+, the eager-loading method is Foo.with_attached_document),
  # we introduce a shim method that all inheritors must implement that the search infrastructure can
  # rely upon. This also gives us the nice ability to refine the eager-load scope in the future if it makes sense,
  # eg) we might return something like +self.with_attached_files.where(front_page: true)+ to only eagerly load
  # the logo attachment for a record with a very large number of attachments like a newspaper, where we are only
  # rendering a search result.
  #
  # Depositables with no attachments should simply choose to return +self+. This is not made the default, else
  # any new model would silently be an N+1 on attachments until somebody noticed the missing implementation. Better
  # to fail fast and noisly during development when we've forgotten to be efficient.
  def self.eager_attachment_scope
    raise MissingImplementationError, 'Depositable models must implement <Class>.eager_attachment_scope'
  end

  # We intend +eager_attachment_scope+ to be the protected method inheritors implement, while the public interface
  # for consumers (primarily the search infrastructure) is +with_eagerly_loaded_attachments+
  class << self; self; end.send :protected, :eager_attachment_scope
  def self.with_eagerly_loaded_attachments; eager_attachment_scope; end

end
