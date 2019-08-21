class ApplicationRecord < ActiveRecord::Base

  self.abstract_class = true

  # this isn't a predicate name you daft thing
  # rubocop:disable Naming/PredicateName
  def self.has_solr_exporter(klass)
    class << self
      attr_accessor :solr_exporter_class
    end
    define_method :solr_exporter do
      return self.solr_exporter_class.new(self)
    end
    define_method :solr_exporter_class do
      return self.class.solr_exporter_class
    end

    self.solr_exporter_class = klass
    after_commit :update_solr
  end
  # rubocop:enable Naming/PredicateName

  def update_solr
    solr_doc = solr_exporter.export
    JupiterCore::SolrServices::Client.instance.add_or_update_document(solr_doc)
  end

  def self.valid_visibilities
    [JupiterCore::VISIBILITY_PUBLIC, JupiterCore::VISIBILITY_PRIVATE, JupiterCore::VISIBILITY_AUTHENTICATED]
  end

  # TODO!!!!! remove
  def unlock_and_fetch_ldp_object
    yield self
    self
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

  def doi_state
    @state ||= ItemDoiState.find_or_create_by!(item_id: id) do |state|
      state.aasm_state = (doi.present? ? :available : :not_available)
    end
  end

  def set_thumbnail(attachment)
    # TODO !!!!!
    return true
    files_attachment_shim.logo_id = attachment.id
    files_attachment_shim.save!
  end

  def thumbnail_url(args = { resize: '100x100', auto_orient: true })
    # TODO !!!
    #logo = files.logo_file
    return nil
    return nil if logo.blank?

    Rails.application.routes.url_helpers.rails_representation_path(logo.variant(args).processed)
  rescue ActiveStorage::InvariableError
    begin
      Rails.application.routes.url_helpers.rails_representation_path(logo.preview(args).processed)
    rescue ActiveStorage::UnpreviewableError
      return nil
    end
  end

  def thumbnail_file
    # TODO !!!
    return nil
    files_attachment_shim.logo_file
  end

  def add_and_ingest_files(file_handles = [])
    return if file_handles.blank?
    raise 'Item not yet saved!' if id.nil?

    file_handles.each do |fileio|
      attachment = files.attach(io: fileio, filename: File.basename(fileio.path)).first
    end
  end

end
