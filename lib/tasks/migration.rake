namespace :migration do
  desc 'migrate communities to jupiter'
  task :communities, [:dir] => :environment do |t, args|
    begin
      MigrationLogger.info "START: Migrate Communities"
      dir = args.dir
      #usage: rake migration:communities['<file directory to community triples, path included>']
      if File.exist?(dir) && File.directory?(dir)
        migrate_communities(dir)
      else
        MigrationLogger.error "Invalid directory #{dir}"
      end
      MigrationLogger.info "FINISHED: Migrate Communities"
    rescue
      raise
    end
  end

  def user_id(email)
    user = User.find_or_create_by(email: email) do |u|
       u.name = user_name(email)
       u.save!
    end
    return user.id
  end

  def user_name(email)
    File.read('users.csv').each_line do |l|
      era_email = l.split("|")[0]
      return l.split("|")[1] if era_email == email
    end
  end 

  def object_value(query_results)
    values = query_results.enum_object.to_a
    return nil if values.count == 0
    if values.count == 1
        return values.first.to_s
    elsif values.count > 1
      return values
    end
  end

  def community_collection_hash(record_file)
    hash = {}
    File.read(record_file).each_line do |l|
      list = l.split(":")
      uuid = list[0]
      noid = list[1].strip
      hash.store(noid, uuid)
    end
    return hash
  end

  def collection_parent_hash(record_file)
    hash = {}
    File.read(record_file).each_line do |l|
      list = l.split(":")
      noid = list[1]
      community = list[2].strip
      hash.store(noid, community)
    end
    return hash
  end

  def migrate_communities(dir)
    File.open('communities.txt','w+') do |f|
      Dir[dir+"/*.nt"].each do |file|
        graph = RDF::Graph.load file
        title = object_value(graph.query(predicate: ::RDF::Vocab::DC.title)) if graph.query(predicate: ::RDF::Vocab::DC.title).count > 0
        hydra_noid = object_value(graph.query(predicate: ::TERMS[:ual].hydraNoid)) if graph.query(predicate: ::TERMS[:ual].hydraNoid).count > 0
        description = object_value(graph.query(predicate: ::RDF::Vocab::DC.description)) if graph.query(predicate: ::RDF::Vocab::DC.description).count > 0 
        fedora3uuid = object_value(graph.query(predicate: ::TERMS[:ual].fedora3UUID)) if graph.query(predicate: ::TERMS[:ual].fedora3UUID).count > 0
        creators = object_value(graph.query(predicate: ::RDF::Vocab::DC.creator)) if graph.query(predicate: ::RDF::Vocab::DC.creator).count > 0
        owner = object_value(graph.query(predicate: ::TERMS[:bibo].owner)) if graph.query(predicate: ::TERMS[:bibo].owner).count > 0 
        community = Community.new_locked_ldp_object(title: title, description: description, fedora3_uuid: fedora3uuid, owner: user_id(owner), creators: creators)
        community.unlock_and_fetch_ldp_object(&:save!)
        puts "#{community.id}:#{hydra_noid}"
        f.write "#{community.id}:#{hydra_noid}\n"
      end
    end
  end

  def migrate_collections(dir)
    File.open('collections.txt', 'w+') do |f|
      Dir[dir+"/*.nt"].each do |file|
        graph = RDF::Graph.load file
        title = object_value(graph.query(predicate: ::RDF::Vocab::DC.title)) if graph.query(predicate: ::RDF::Vocab::DC.title).count > 0
        hydra_noid = object_value(graph.query(predicate: ::TERMS[:ual].hydraNoid)) if graph.query(predicate: ::TERMS[:ual].hydraNoid).count > 0
        description = object_value(graph.query(predicate: ::RDF::Vocab::DC.description)) if graph.query(predicate: ::RDF::Vocab::DC.description).count > 0
        fedora3uuid = object_value(graph.query(predicate: ::TERMS[:ual].fedora3UUID)) if graph.query(predicate: ::TERMS[:ual].fedora3UUID).count > 0
        creators = object_value(graph.query(predicate: ::RDF::Vocab::DC11.creator)) if graph.query(predicate: ::RDF::Vocab::DC.creator).count > 0
        owner = object_value(graph.query(predicate: ::TERMS[:bibo].owner)) if graph.query(predicate: ::TERMS[:bibo].owner).count > 0
        community_uri = object_value(graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)) if graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf).count > 0
        community_hash = community_collection_hash('communities.txt')
        if community_uri.nil?
        puts "#{hydra_noid} don't have community"
        else
        community_noid = community_uri.split('/')[-1] if !community_uri.nil?
        community_id = community_hash[community_noid]
        collection = Collection.new_locked_ldp_object(title: title, description: description, fedora3_uuid: fedora3uuid, owner: user_id(owner), creators: creators, community_id: community_id)
        collection.unlock_and_fetch_ldp_object(&:save!)
        puts "#{collection.id}:#{hydra_noid}:#{community_id}"
        f.write "#{collection.id}:#{hydra_noid}:#{community_id}\n"
        end
      end
    end 
  end

  def migrate_generic(dir)
    File.open('generic.txt','w+') do |f|
      Dir[dir+"/*.nt"].each do |file|
        graph  = RDF::Graph.load file
        config = YAML::load_file('config/locales/en.yml')
        title = object_value(graph.query(predicate: ::RDF::Vocab::DC.title)) if graph.query(predicate: ::RDF::Vocab::DC.title).count > 0
        hydra_noid = object_value(graph.query(predicate: ::TERMS[:ual].hydraNoid)) if graph.query(predicate: ::TERMS[:ual].hydraNoid).count > 0
        description = object_value(graph.query(predicate: ::RDF::Vocab::DC.description)) if graph.query(predicate: ::RDF::Vocab::DC.description).count > 0
        fedora3uuid = object_value(graph.query(predicate: ::TERMS[:ual].fedora3UUID)) if graph.query(predicate: ::TERMS[:ual].fedora3UUID).count > 0
        creators = object_value(graph.query(predicate: ::RDF::Vocab::DC11.creator)) if graph.query(predicate: ::RDF::Vocab::DC.creator).count > 0
        owner = object_value(graph.query(predicate: ::TERMS[:bibo].owner)) if graph.query(predicate: ::TERMS[:bibo].owner).count > 0
        contributors = object_value(graph.query(predicate: ::RDF::Vocab::DC11.contributor)) 
        created = object_value(graph.query(predicate: ::RDF::Vocab::DC.created))
        sort_year = object_value(graph.query(predicate: ::TERMS[:ual].sortyear))
        subject = object_value(graph.query(predicate: ::RDF::Vocab::DC11.subject))
        temporal_subjects = object_value(graph.query(predicate: ::RDF::Vocab::DC.temporal))
        spatial_subjects = object_value(graph.query(predicate: ::RDF::Vocab::DC.spatial))
        publisher = object_value(graph.query(predicate: ::RDF::Vocab::DC.publisher))
        language = object_value(graph.query(predicate: ::RDF::Vocab::DC.language))
        lang_code = config["en"]["controlled_vocabularies"]["language"].key(language)
        language_uri = CONTROLLED_VOCABULARIES[:language].find { |pair| pair[:code] == lang_code }[:uri]        
        embargo_end_date = object_value(graph.query(predicate: ::RDF::Vocab::DC.available))
        license = object_value(graph.query(predicate: ::RDF::Vocab::DC.license))
        license_code = config["en"]["controlled_vocabularies"]["license"].key(license)
        license_uri = CONTROLLED_VOCABULARIES[:license].find { |pair| pair[:code]==license_code }[:uri]
	rights = object_value(graph.query(predicate: ::RDF::Vocab::DC11.rights))
        item_type = object_value(graph.query(predicate: ::RDF::Vocab::DC.type))
        if item_type.nil?
          puts "#{hydra_noid} doesn't have valid item_type"
        else
          if item_type.match(/^Journal/)
            item_type.gsub!("Journal ","")
          end
          item_type_code = config["en"]["controlled_vocabularies"]["item_type_with_status"].key(item_type)
          if item_type_code.start_with?('article')
            publication_status = item_type_code.split("_")[1]
            item_type_code = "article"
          else
            publication_status = nil
          end
          item_type_uri = CONTROLLED_VOCABULARIES[:item_type].find { |pair| pair[:code] == item_type_code }[:uri]

          if !publication_status.nil?
            publication_status_uri = CONTROLLED_VOCABULARIES[:publication_status].find { |pair| pair[:code] == publication_status }[:uri]
          end
        end
 
        derived_from = object_value(graph.query(predicate: ::RDF::Vocab::DC.source))
        is_version_of = object_value(graph.query(predicate: ::RDF::Vocab::DC.isVersionOf))
        alternative_title = object_value(graph.query(predicate: ::RDF::Vocab::DC.alternative))
        related_link = object_value(graph.query(predicate: ::RDF::Vocab::DC.relation))
        depositor = object_value(graph.query(predicate: ::TERMS[:ual].depositor))
        fedora3handle = object_value(graph.query(predicate: ::TERMS[:ual].fedora3handle))
        doi = object_value(graph.query(predicate: ::TERMS[:prism].doi))
        embargo_history = object_value(graph.query(predicate: ::TERMS[:acl].embargoHistory))
        visibility_after_embargo = object_value(graph.query(predicate: ::TERM[:acl].visibilityAfterEmbargo))

        collection_uri = object_value(graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)) if graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf).count > 0
        collection_hash = community_collection_hash('collections.txt')
        collection_community = collection_parent_hash('collections.txt')
        if collection_uri.nil?
          puts "#{hydra_noid} do not have a collection"
        else
          collection_noid = collection_uri.split('/')[-1] if !collection_uri.nil?
          collection_id = collection_hash[collection_noid]
          community_id = collection_community[collection_noid]
          path = "#{community_id}/#{collection_id}"
        end
        file_dir = "tmp/#{hydra_noid}"
        `mkdir -p #{file_dir} && cd #{file_dir} &&  wget --content-disposition -q -N https://era.library.ualberta.ca/downloads/#{hydra_noid}`
        files = Dir["#{file_dir}/*"]
        item = Item.new_locked_ldp_object(title: title, creators: creators, contributors: contributors, created: created, subject: subject, publisher: publisher, languages: [language_uri], license: license_uri, item_type: item_type_uri, publication_status: publication_status_uri, depositor: depositor, owner: 27, visibility: JupiterCore::VISIBILITY_PUBLIC, fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle, member_of_paths: [member_of_paths], doi: doi)
        item.unlock_and_fetch_ldp_object(&:save!)
        if !files.empty?
          File.open(files.first) do |f|
            item.unlock_and_fetch_ldp_object do |uo|
              uo.add_files([f])
              `rm -rf #{file_dir}`
            end
          end
        end
        puts "#{item.id}:#{id}"
      end
    end
  end

end
