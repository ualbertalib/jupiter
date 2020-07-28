class Aip::V1::EntitiesController < ApplicationController

  ITEM_CLASS_NAME = Item.name.freeze
  THESIS_CLASS_NAME = Thesis.name.freeze
  ITEM_INSTITUTIONAL_REPOSITORY_NAME = 'IRItem'.freeze
  THESIS_INSTITUTIONAL_REPOSITORY_NAME = 'IRThesis'.freeze
  FILESET_INSTITUTIONAL_REPOSITORY_NAME = 'IRFileSet'.freeze
  ENTITY_INSTITUTIONAL_REPOSITORY_NAME = 'IREntity'.freeze

  before_action :load_entity, only: [:show, :file_sets, :file_paths, :file_set]
  before_action :load_file, only: [:file_set, :fixity_file, :original_file]
  before_action :ensure_access

  def show
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
      ::TERMS[:fedora].schema,
      RDF::Vocab::Fcrepo4.created,
      RDF::Vocab::Fcrepo4.createdBy,
      RDF::Vocab::Fcrepo4.lastModified,
      RDF::Vocab::Fcrepo4.lastModifiedBy
    ]

    rdf_graph_creator = RdfGraphCreationService.new(@entity, prefixes, self_subject)

    # The following nodes are statements/lists that are required for entitites
    # but are not directly referenced by a predicate in the system because they
    # require some level of processing to obtain.

    rdf_graph_creator.graph.insert(
      owner_email_statement,
      entity_model_statement,
      *entity_type_statements,
      *entity_file_statements,
      *entity_member_of_statements
    )

    # Creators and contributors are a special case where we also need to maintain the order of their values, for this
    # reason we add the sorted rdf list for predicates authorList and contributorList respectively
    # This comes from: https://github.com/ualbertalib/jupiter/issues/333

    rdf_graph_creator.copy_predicate_to_sorted_rdf_list(
      self_subject,
      RDF::Vocab::DC11.creator,
      RDF::Vocab::BIBO.authorList
    )
    rdf_graph_creator.copy_predicate_to_sorted_rdf_list(
      self_subject,
      RDF::Vocab::DC11.contributor,
      RDF::Vocab::BIBO.contributorList
    )

    # Thesis predicates that need to be added as sorted lists
    rdf_graph_creator.copy_predicate_to_sorted_rdf_list(
      self_subject,
      TERMS[:ual].department,
      TERMS[:ual].department_list
    )
    rdf_graph_creator.copy_predicate_to_sorted_rdf_list(
      self_subject,
      TERMS[:ual].supervisor,
      TERMS[:ual].supervisor_list
    )

    # Handle special case where predicate http://projecthydra.org/ns/auth/acl#embargoHistory needs to maintain the order
    # in which it was entered. The original nodes the predicate are removed and a new rdf list is inserted instead with
    # the predicate

    rdf_graph_creator.replace_predicate_with_sorted_rdf_list(self_subject, ::TERMS[:acl].embargo_history)

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
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

    rdf_graph_creator = RdfGraphCreationService.new(@file.blob, prefixes, self_subject)

    file_view_uri = RDF::URI(
      file_view_item_url(
        id: @entity.id,
        file_set_id: @file.fileset_uuid,
        file_name: @file.filename.to_s
      )
    )

    statements = [
      owner_email_statement,
      *entity_member_of_statements,
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PCDM.Object),
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::Fcrepo4.Resource),
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::Fcrepo4.Container),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::DC.accessRights, object: @entity.visibility),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::EBUCore.dateIngested, object: @entity.date_ingested),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::Fcrepo4.hasParent, object: self_subject.parent),
      RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::PCDM.hasFile,
        object: self_subject / 'original_file'
      ),
      RDF::Statement(
        subject: self_subject,
        predicate: TERMS[:ual].record_created_in_jupiter,
        object: @entity.record_created_at
      ),
      RDF::Statement(
        subject: self_subject,
        predicate: ::TERMS[:fedora].has_model,
        object: FILESET_INSTITUTIONAL_REPOSITORY_NAME
      ),
      RDF::Statement(
        subject: self_subject,
        predicate: ::TERMS[:ual].sitemap_link,
        object: RDF::URI('rs:ln') + " href=\"#{file_view_uri.path}\" rel=\"content\" hash=\"md5:#{@file.checksum}\" " \
                "length=\"#{@file.byte_size}\" type=\"#{@file.content_type}\""
      )
    ]

    rdf_graph_creator.graph.insert(*statements)

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
  end

  def fixity_file
    # Prefix provided by the metadata team
    prefixes = [RDF::Vocab::PREMIS]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)

    subject = RDF::URI(request.url.split('/')[0..-2].join('/'))

    rdf_graph_creator = RdfGraphCreationService.new(
      @file.blob, prefixes, subject
    )

    statements = [
      RDF::Statement(subject: subject, predicate: RDF::Vocab::PREMIS.hasFixity, object: self_subject),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::PREMIS.hasEventOutcome, object: 'SUCCESS'),
      RDF::Statement(subject: self_subject, predicate: RDF::Vocab::PREMIS.hasMessageDigestAlgorithm, object: 'md5'),
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PREMIS.EventOutcomeDetail),
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PREMIS.Fixity)
    ]

    rdf_graph_creator.graph.insert(*statements)

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
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

    rdf_graph_creator = RdfGraphCreationService.new(@file.blob, prefixes, self_subject)
    insert_nodes = [
      RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PCDM.File),
      RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::Fcrepo4.hasFixityService,
        object: self_subject.parent / 'fixity'
      ),
      # We need to change the value for the predicate RDF::Vocab::PREMIS.hasMessageDigest so that it includes the
      # uniform resource name with the algorightm used to create the checksum. In this case, we know that Active storage
      # uses MD5
      RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::PREMIS.hasMessageDigest,
        object: RDF::URI.new('urn:md5') / @file.blob.checksum
      ),
      RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::Fcrepo4.hasParent,
        object: self_subject.parent
      )
    ]

    rdf_graph_creator.graph.delete_insert(
      rdf_graph_creator.graph.query(predicate: RDF::Vocab::PREMIS.hasMessageDigest), insert_nodes
    )

    render plain: rdf_graph_creator.graph.to_n3, status: :ok
  end

  def file_paths
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
    when ITEM_CLASS_NAME
      ITEM_INSTITUTIONAL_REPOSITORY_NAME
    when THESIS_CLASS_NAME
      THESIS_INSTITUTIONAL_REPOSITORY_NAME
    else
      ENTITY_INSTITUTIONAL_REPOSITORY_NAME
    end
  end

  def load_file
    @file = ActiveStorage::Attachment.find_by(fileset_uuid: params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file.record_id == params[:id]
  end

  def load_entity
    case params[:entity]
    # There is a routing constraint specifying which models are available
    # through the url. We need to update the routing constraint whenever a new
    # entity is made available
    when Item.table_name
      @entity = Item.find(params[:id])
    when Thesis.table_name
      @entity = Thesis.find(params[:id])
    end
  end

  def ensure_access
    authorize :aip, :access?
  end

  private

  def self_subject
    RDF::URI(request.url)
  end

  def owner_email_statement
    RDF::Statement(subject: self_subject, predicate: RDF::Vocab::BIBO.owner, object: @entity.owner.email)
  end

  def entity_file_statements
    file_statements = []

    @entity.files.each do |file|
      file_statements << RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::PCDM.hasMember,
        object: RDF::URI.new("#{request.original_url}/filesets/#{file.fileset_uuid}")
      )
    end

    file_statements
  end

  def entity_member_of_statements
    # To set the value for the predicate http://pcdm.org/models#memberOf we use
    # the data from column member_of_paths, strip the collection id, and
    # concatenate the url for the collection.

    statements = []
    @entity.member_of_paths.each do |community_collection|
      collection_id = community_collection.split('/')[1]
      aip_base_url = request.url.split('/')[0..-3].join('/')
      collection_url = "#{aip_base_url}/collections/#{collection_id}"

      statements << RDF::Statement(
        subject: self_subject,
        predicate: RDF::Vocab::PCDM.memberOf,
        object: RDF::URI.new(collection_url)
      )
    end
    statements
  end

  def entity_model_statement
    RDF::Statement(
      subject: self_subject,
      predicate: ::TERMS[:fedora].has_model,
      object: entity_institutional_repository_name
    )
  end

  def entity_type_statements
    statements = [RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::PCDM.Object)]
    if @entity.class.to_s == THESIS_CLASS_NAME
      statements << RDF::Statement(subject: self_subject, predicate: RDF.type, object: RDF::Vocab::BIBO.Thesis)
    end

    statements
  end

end
