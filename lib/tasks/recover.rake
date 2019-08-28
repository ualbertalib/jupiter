namespace :jupiter do
  desc 'recover complete Solr index from data stored in Fedora, in the event of catastrophic loss of Solr data'
  task recover: :environment do
    puts 'Starting Recovery'

    # referencing the classes ensures they're eager loaded even if this gets run in an envrionment that lazy-loads
    # the AF IR{Classes} are instantiated when these classes load, so they need to be loaded prior to any call to
    # ActiveFedora::Base#find
    RECOVERED_CLASSES = [Thesis, Item, Collection, Community, FileSet].freeze

    # Unfortunately, an inter-object dependency crept into the way we're using +additional_search_index+ in Collection.
    # Collections attempt to retrieve a Community to index its title into Solr, without saving that information to
    # Fedora – this creates an ordering dependency between Collections and Communities such that the Community needs
    # to be indexed prior to indexing the Collection, but we cannot request that we receive all Community objects
    # in Fedora prior to receiving any Collection objects, so we must delay all Collection URIs manually, and
    # process them last. (if this had been a more complicated ordering dependency between 40,000+ FileSets and Items,
    # we'd be in a very difficult spot right now)
    delayed_collections = []

    rdf_source = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.build_connection, ActiveFedora.fedora.base_uri)

    uris = rdf_source.graph.query(predicate: ::RDF::Vocab::LDP.contains).map { |ldp_uri| ldp_uri.object.to_s }
    count = uris.count

    puts
    puts "Generating Solr data for #{count} objects found in Fedora at #{ActiveFedora.fedora.base_uri}"
    uris.each_with_index do |uri, idx|
      ir_object = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri))

      if ir_object.class == IRCollection
        delayed_collections << uri
        next
      end

      add_to_solr(ir_object)
      update_progress(idx, count)
    end

    delayed_collections.each_with_index do |uri, idx|
      ir_object = ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri))
      add_to_solr(ir_object)
      update_progress(idx, count)
    end

    puts 'Recovery completed!'
  end

  def update_progress(idx, count)
    if idx % 50 == 0
      puts
      print "#{idx}/#{count}"
    else
      print '.'
    end
  end

  def add_to_solr(ir_object)
    klass = ir_object.class.owning_class
    object = klass.send(:new, ldp_obj: ir_object)

    solr_data = {}
    object.tap { |uo| solr_data = uo.to_solr }
    JupiterCore::SolrServices::Client.instance.connection.add(solr_data, 'softCommit' => true)
  end
end
