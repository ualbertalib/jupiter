class Aip::V1::AipController < ApplicationController

  # load_and_authorize_asset method needs to be defined on the subclasses where
  # different type of object is required
  before_action :load_and_authorize_asset, only: [:show, :file_sets]
  before_action :load_and_authorize_file, only: [
    :file_set,
    :fixity_file,
    :download_file,
    :original_file
  ]

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
      ::TERMS[:fedora].schema + ::TERMS[:fedora].has_model,
      RDF::Vocab::Fcrepo4.created,
      RDF::Vocab::Fcrepo4.createdBy,
      RDF::Vocab::Fcrepo4.lastModified,
      RDF::Vocab::Fcrepo4.lastModifiedBy,
      RDF::Vocab::Fcrepo4.writable
    ]
    graph = create_graph(@asset, prefixes)

    # Handle files separately since currently they are not a part of the
    # acts_as_rdfable table entries

    file_statements.each { |file_statement| graph << file_statement }

    # Add owners email seperatedly because there is currently no predicate set
    # to specify this relation directly

    owners_email = owner_email_statement
    graph << owners_email unless owners_email.nil?

    triples = graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def file_sets
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.file_order do
        @asset.files.each do |file|
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

    triples = graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def fixity_file
    # Prefix provided by the metadata team
    prefixes = [RDF::Vocab::PREMIS]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)

    subject = RDF::URI(request.url.split('/')[0..-2].join('/'))
    graph = create_graph(@file.blob, prefixes, subject)

    statements = []
    statements << prepare_statement(
      subject: subject,
      predicate: RDF::Vocab::PREMIS.hasFixity,
      object: self_subject
    )

    statements << prepare_statement(
      subject: subject,
      predicate: RDF::Vocab::PREMIS.hasEventOutcome,
      object: 'SUCCESS'
    )

    statements << prepare_statement(
      subject: subject,
      predicate: RDF::Vocab::PREMIS.hasMessageDigestAlgorithm,
      object: 'md5'
    )

    statements.each do |statement|
      graph << statement unless statement.nil?
    end

    triples = graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def original_file
    prefixes = [
      RDF::Vocab::EBUCore,
      RDF::Vocab::PREMIS,
      RDF::Vocab::DC11,
      # The following prefixes need to be reevaluated and replaced
      RDF::Vocab::Fcrepo4,
      ::TERMS[:fits].schema,
      ::TERMS[:odf].schema,
      ::TERMS[:semantic].schema
    ]

    ActsAsRdfable.add_annotation_bindings!(@file.blob)
    graph = create_graph(@file.blob, prefixes)

    # add fixity service url

    triples = graph.dump(:n3)
    render plain: triples, status: :ok
  end

  def download_file
    send_data(
      ActiveStorage::Blob.service.download(@file.blob.key),
      disposition: 'attachment',
      type: @file.blob.content_type,
      filename: @file.filename.to_s
    )
  end

  protected

  def create_graph(rdfable_asset, prefixes, subject = nil)
    subject = self_subject if subject.nil?
    graph = RDF::Graph.new
    annotations = get_prefixed_predicates(rdfable_asset, prefixes)

    annotations.each do |rdf_annotation|
      column = rdf_annotation.column
      value = rdfable_asset.send(column)

      statement = prepare_statement(
        subject: subject,
        predicate: rdf_annotation.predicate,
        object: value
      )

      graph << statement unless statement.nil?
    end

    graph
  end

  def get_prefixed_predicates(rdfable_asset, prefixes)
    result = RdfAnnotation.none
    ActsAsRdfable.add_annotation_bindings!(rdfable_asset)
    prefixes.each do |prefix|
      result = result.or rdfable_asset.rdf_annotations
                                      .where('predicate like :prefix',
                                             prefix: "#{prefix}%")
    end
    result
  end

  def prepare_statement(subject:, predicate:, object:)
    return if object.nil?

    object = [object] unless object.is_a?(Array)
    rdf_predicate = RDF::Vocabulary::Term.new(predicate)
    stringed_value = object.join(' , ')

    RDF::Statement(
      subject: subject,
      predicate: rdf_predicate,
      object: stringed_value
    )
  end

  def file_statements
    file_statements = []
    @asset.files.each do |file|
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

  def owner_email_statement
    prepare_statement(
      subject: self_subject,
      predicate: RDF::Vocab::BIBO.owner,
      object: @asset.owner.email
    )
  end

  # Copied from /app/controllers/downloads_controller.rb
  def load_and_authorize_file
    @file = ActiveStorage::Attachment.find_by(fileset_uuid: params[:file_set_id])
    raise JupiterCore::ObjectNotFound unless @file.record_id == params[:id]

    authorize @file, :download_file?
  end

  # Return the url from the request to be used as the statement's subject for
  # each rdf annotation for the requested digital object
  def self_subject
    RDF::URI(request.url)
  end

  def load_and_authorize_asset
    case params[:model]
    when Item.name.underscore.pluralize
      @asset = Item.find(params[:id])
    when Thesis.name.underscore.pluralize
      @asset = Thesis.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end

    authorize @asset
  end

end
