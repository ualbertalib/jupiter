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
      collection_hash = community_collection_hash('collections.txt')
      collection_community = collection_parent_hash('collections.txt')   
      File.open('generic.txt','w+') do |f|
        Dir[dir+"/*.nt"].each do |file|

          graph  = RDF::Graph.load file
          config = YAML::load_file('config/locales/en.yml')
          title = object_value(graph.query(predicate: ::RDF::Vocab::DC.title)) if graph.query(predicate: ::RDF::Vocab::DC.title).count > 0
          hydra_noid = object_value(graph.query(predicate: ::TERMS[:ual].hydraNoid)) if graph.query(predicate: ::TERMS[:ual].hydraNoid).count > 0
          description = object_value(graph.query(predicate: ::RDF::Vocab::DC.description)) if graph.query(predicate: ::RDF::Vocab::DC.description).count > 0
          fedora3uuid = object_value(graph.query(predicate: ::TERMS[:ual].fedora3UUID)) if graph.query(predicate: ::TERMS[:ual].fedora3UUID).count > 0
          creators = object_value(graph.query(predicate: ::RDF::Vocab::DC11.creator)).map!{|c| c.value} if graph.query(predicate: ::RDF::Vocab::DC11.creator).count > 0
          owner = object_value(graph.query(predicate: ::TERMS[:bibo].owner)) if graph.query(predicate: ::TERMS[:bibo].owner).count > 0
	  depositor = object_value(graph.query(predicate: ::TERMS[:ual].depositor))

          if owner.nil?
            owner = depositor
          end
          contributors = object_value(graph.query(predicate: ::RDF::Vocab::DC11.contributor))
          created = object_value(graph.query(predicate: ::RDF::Vocab::DC.created))
          sort_year = object_value(graph.query(predicate: ::TERMS[:ual].sortyear))
          subject = object_value(graph.query(predicate: ::RDF::Vocab::DC11.subject)).map! {|s| s.value}

          temporal_subjects = object_value(graph.query(predicate: ::RDF::Vocab::DC.temporal)).map! {|s| s.value}
          spatial_subjects = object_value(graph.query(predicate: ::RDF::Vocab::DC.spatial)).map! {|s| s.value}
          publisher = object_value(graph.query(predicate: ::RDF::Vocab::DC.publisher))
          language = object_value(graph.query(predicate: ::RDF::Vocab::DC.language))

          embargo_end_date = object_value(graph.query(predicate: ::RDF::Vocab::DC.available))
          license = object_value(graph.query(predicate: ::RDF::Vocab::DC.license))

          rights = object_value(graph.query(predicate: ::RDF::Vocab::DC11.rights))
          item_type = object_value(graph.query(predicate: ::RDF::Vocab::DC.type))
	  publication_status = object_value(graph.query(predicate: ::TERMS[:bibo].status))

          derived_from = object_value(graph.query(predicate: ::RDF::Vocab::DC.source))
          is_version_of = object_value(graph.query(predicate: ::RDF::Vocab::DC.isVersionOf))
          alternative_title = object_value(graph.query(predicate: ::RDF::Vocab::DC.alternative))
          related_link = object_value(graph.query(predicate: ::RDF::Vocab::DC.relation))
          fedora3handle = object_value(graph.query(predicate: ::TERMS[:ual].fedora3handle))
          doi = object_value(graph.query(predicate: ::TERMS[:prism].doi))
          embargo_history = object_value(graph.query(predicate: ::TERMS[:acl].embargoHistory))
          visibility_after_embargo = object_value(graph.query(predicate: ::TERMS[:acl].visibilityAfterEmbargo))
          visibility = object_value(graph.query(predicate: ::RDF::Vocab::DC.accessRights))
          if visibility.nil?
            visibility = JupiterCore::VISIBILITY_PUBLIC
          end
          collection_uri = object_value(graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)) if graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf).count > 0

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
          puts hydra_noid

        
          item = Item.new_locked_ldp_object(title: title, creators: creators, contributors: contributors, 
              created: created, sort_year:sort_year, temporal_subjects: temporal_subjects, spatial_subjects: spatial_subjects, subject: subject, 
              publisher: publisher, languages: [language], license: license, rights: rights, item_type: item_type, publication_status: publication_status,
              derived_from: derived_from, is_version_of: is_version_of, alternative_title: alternative_title, related_link: related_link, 
              embargo_end_date: embargo_end_date, embargo_history: embargo_history, visibility_after_embargo: visibility_after_embargo, 
              depositor: depositor, owner: user_id(owner), visibility: visibility, fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle, 
             member_of_paths: [path], doi: doi)


      

         item.unlock_and_fetch_ldp_object(&:save!)
         if !files.empty?
           File.open(files.first) do |f|
             item.unlock_and_fetch_ldp_object do |uo|
               uo.add_files([f])
               `rm -rf #{file_dir}`
             end
           end
         end
         puts "#{item.id}:#{hydra_noid}"
	 f.write "#{item.id}:#{hydra_noid}\n"
        
       end
     end
  end

end
