class Aip::V1::EntitiesController < ApplicationController

  include GraphCreation

  before_action :load_and_authorize_entity, only: [
    :show_entity,
    :file_sets,
    :file_paths
  ]

  before_action :load_and_authorize_file, only: [
    :file_set,
    :fixity_file,
    :original_file
  ]

  def show_entity
    # These are the prefixes defined as required by the metadata team. The
    # hardcoded strings need to be replaced. The namespaces could be added to
    # the rdf-vocab gem.
    # The fedora prefixes will be replaced at a later point from another
    # ontology, for now these remain as placeholders.

    prefixes = [
      RDF::Vocab::DC,
      RDF::Vocab::DC11,
      ::TERMS[:ual].schema,
      RDF::Vocab::PCDM,
      ::TERMS[:prism].schema,
      RDF::Vocab::BIBO,
      ::TERMS[:swrc].schema,
      ::TERMS[:acl].schema,
      RDF::Vocab::EBUCore,
      # The following prefixes need to be reevaluated and replaced
      ::TERMS[:fedora].schema + ::TERMS[:fedora].has_model,
      RDF::Vocab::Fcrepo4.created,
      RDF::Vocab::Fcrepo4.createdBy,
      RDF::Vocab::Fcrepo4.lastModified,
      RDF::Vocab::Fcrepo4.lastModifiedBy,
      RDF::Vocab::Fcrepo4.writable
    ]

    graph = create_graph(@entity, prefixes)

    # Handle files separately since currently they are not a part of the
    # acts_as_rdfable table entries

    file_statements.each { |file_statement| graph << file_statement }

    # Add owners email seperatedly because there is currently no predicate set
    # to specify this relation directly

    owners_email = owner_email_statement
    graph << owners_email unless owners_email.nil?

    graph << rdf_type_statement(RDF::Vocab::PCDM.Object)

    # To set the value for the predicate http://pcdm.org/models#memberOf we use
    # the data from column member_of_paths, strip the collection id, and
    # concatenate the url for the collection. This should be done cleaner

    @entity.member_of_paths.each do |community_collection|
      collection_id = community_collection.split('/')[1]
      aip_base_url = request.url.split('/')[0..-3].join('/')
      collection_url = "#{aip_base_url}/collections/#{collection_id}"

      graph << prepare_statement(
        subject: self_subject,
        predicate: RDF::Vocab::PCDM.memberOf,
        object: RDF::URI.new(collection_url)
      )
    end

    # Add entity model
    graph << prepare_statement(
      subject: self_subject,
      predicate: RDF::URI.new('info:fedora/fedora-system:def/model#hasModel'),
      object: entity_institutional_repository_name
    )

    render plain: graph.to_n3, status: :ok
  end

  def file_sets
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.file_order do
        @entity.files.each do |file|
          # The underscore for xml.uuid_ is intentional. Nokogiri builder makes
          # use of method_missing to create its xml model. There could be
          # problems with preexisting methods so we play it safe and add an
          # underscore to avoid unintended behaviuor. You can find more info here:
          # https://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Builder
          xml.uuid_ file.fileset_uuid
        end
      end
    end
    render xml: builder.to_xml
  end

  def file_set
    # Prefixes provided by the metadata team
    # The fedora prefixes will be replaced at a later point from another
    # ontology, for now these remain as placeholders.
    prefixes = [
      RDF::Vocab::DC,
      ::TERMS[:ual].schema,
      RDF::Vocab::PCDM,
      RDF::Vocab::BIBO,
      RDF::Vocab::EBUCore,
      # The following prefixes need to be reevaluated and replaced
      ::TERMS[:fedora].schema + ::TERMS[:fedora].has_model,
      RDF::Vocab::Fcrepo4.created,
      RDF::Vocab::Fcrepo4.createdBy,
      RDF::Vocab::Fcrepo4.lastModified,
      RDF::Vocab::Fcrepo4.lastModifiedBy,
      RDF::Vocab::Fcrepo4.writable
    ]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)
    graph = create_graph(@file.blob, prefixes)
    graph << rdf_type_statement(RDF::Vocab::PCDM.Object)

    render plain: graph.to_n3, status: :ok
  end

  def fixity_file
    # Prefix provided by the metadata team
    prefixes = [RDF::Vocab::PREMIS]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)

    subject = RDF::URI(request.url.split('/')[0..-2].join('/'))
    graph = create_graph(@file.blob, prefixes, self_subject)

    statement_definitions = [
      {
        subject: subject,
        predicate: RDF::Vocab::PREMIS.hasFixity,
        object: self_subject
      },
      {
        subject: self_subject,
        predicate: RDF::Vocab::PREMIS.hasEventOutcome,
        object: 'SUCCESS'
      },
      {
        subject: self_subject,
        predicate: RDF::Vocab::PREMIS.hasMessageDigestAlgorithm,
        object: 'md5'
      },
      {
        subject: self_subject,
        predicate: RDF.type,
        object: RDF::Vocab::PREMIS.EventOutcomeDetail
      },
      {
        subject: self_subject,
        predicate: RDF.type,
        object: RDF::Vocab::PREMIS.Fixity
      }
    ]

    statement_definitions.each do |statement_definition|
      statement = prepare_statement(statement_definition)
      graph << statement unless statement.nil?
    end

    render plain: graph.to_n3, status: :ok
  end

  def original_file
    prefixes = [
      RDF::Vocab::EBUCore,
      RDF::Vocab::PREMIS,
      RDF::Vocab::DC11,
      RDF::Vocab::PCDM,
      # The following prefixes need to be reevaluated and replaced
      RDF::Vocab::Fcrepo4,
      ::TERMS[:fits].schema,
      ::TERMS[:odf].schema,
      ::TERMS[:semantic].schema
    ]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)
    graph = create_graph(@file.blob, prefixes)
    graph << rdf_type_statement(RDF::Vocab::PCDM.File)

    # add fixity service url

    render plain: graph.to_n3, status: :ok
  end

  def file_paths
    result = []
    result = { files: [] }

    @entity.files.each do |file|
      # TODO: Consider using olive branch for formating response with camel case keys
      entry = {
        file_name: file.blob.filename,
        file_path: ActiveStorage::Blob.service.send(:path_for, file.blob.key),
        file_uuid: file.fileset_uuid,
        file_checksum: file.blob.checksum
      }

      result[:files] << entry
    end
    render json: result.to_json
  end

  protected

  def entity_institutional_repository_name
    case @entity.class.to_s
    when 'Item'
      return 'IRItem'
    when 'Thesis'
      return 'IRThesis'
    end

    'IREntity'
  end

  def file_statements
    file_statements = []

    @entity.try(:files).try(:each) do |file|
      fileset_url = "#{request.original_url}/filesets/#{file.fileset_uuid}"
      statement = prepare_statement(
        subject: self_subject,
        predicate: RDF::Vocab::PCDM.hasMember,
        object: fileset_url
      )
      file_statements << statement unless statement.nil?
    end

    file_statements
  end

  def load_and_authorize_file
    @file = ActiveStorage::Attachment.find_by(fileset_uuid: params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file.record_id == params[:id]

    authorize @file
  end

  def load_and_authorize_entity
    case params[:entity]
    # There is a routing constraint specifying which models are available
    # through the url. We need to update the routing constraint whenever a new
    # entity is made available
    when Item.name.underscore.pluralize
      @entity = Item.find(params[:id])
    when Thesis.name.underscore.pluralize
      @entity = Thesis.find(params[:id])
    end

    authorize @entity
  end

end
