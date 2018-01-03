require 'tasks/migration/migration_logger'

namespace :migration do
  desc 'migrate communities to jupiter'
  task :communities, [:dir] => :environment do |_t, args|
    begin
      MigrationLogger.info 'START: Migrate Communities'
      dir = args.dir
      # usage: rake migration:communities['<file directory to community triples, path included>']
      if File.exist?(dir) && File.directory?(dir)
        migrate_communities(dir)
      else
        MigrationLogger.error "Invalid directory #{dir}"
      end
      MigrationLogger.info 'FINISHED: Migrate Communities'
    rescue StandardError
      raise
    end
  end

  desc 'migrate collections to jupiter'
  task :collections, [:dir] => :environment do |_t, args|
    begin
      MigrationLogger.info 'START: Migrate Collections'
      dir = args.dir
      # usage: rake migration:collections['<file directory to collection triple files, path included>']
      if File.exist?(dir) && File.directory?(dir)
        migrate_collections(dir)
      else
        MigrationLogger.error "Invalid directory #{dir}"
      end
      MigrationLogger.info 'FINISHED: Migrate Collections'
    rescue StandardError
      raise
    end
  end

  desc 'migrate items to jupiter'
  task :items, [:dir] => :environment do |_t, args|
    begin
      MigrationLogger.info 'START: Migrate generic items'
      dir = args.dir
      # usage: rake migration:items['<file directory to item triple files, path included>']
      if File.exist?(dir) && File.directory?(dir)
        migrate_items(dir)
      else
        MigrationLogger.error "Invalid directory #{dir}"
      end
      MigrationLogger.info 'FINISHED: Migrate generic items'
    rescue StandardError
      raise
    end
  end

  def user_id(email)
    l = File.foreach('users.csv').grep(/#{email}/)
    ccid = l.first.split('|')[4].strip
    name = l.first.split('|')[1].strip
    email = ccid + '@ualberta.ca' if ccid.present?
    puts email
    user = User.find_or_create_by(email: email) do |u|
      u.name = name
      u.save!
    end
    user.id
  end

  def object_value(query_results)
    values = query_results.enum_object.to_a
    return nil if values.count == 0
    return values.first.to_s if values.count == 1
    return values if values.count > 1
  end

  def community_collection_hash(record_file)
    hash = {}
    File.read(record_file).each_line do |l|
      list = l.split(':')
      uuid = list[0]
      noid = list[1].strip
      hash.store(noid, uuid)
    end
    hash
  end

  def collection_parent_hash(record_file)
    hash = {}
    File.read(record_file).each_line do |l|
      list = l.split(':')
      noid = list[1]
      community = list[2].strip
      hash.store(noid, community)
    end
    hash
  end

  def multiple_value(attribute)
    if attribute.is_a? Array
      attribute.map!(&:value)
    elsif attribute.is_a? String
      attribute = [attribute]
    end
    attribute
  end

  def migrate_communities(dir)
    File.open('communities.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        title_query = graph.query(predicate: ::RDF::Vocab::DC.title)
        title = object_value(title_query) if title_query.count > 0
        hydra_noid_query = graph.query(predicate: ::TERMS[:ual].hydraNoid)
        hydra_noid = object_value(hydra_noid_query) if hydra_noid_query.count > 0
        description_query = graph.query(predicate: ::RDF::Vocab::DC.description)
        description = object_value(description_query) if description_query.count > 0
        fedora3uuid_query = graph.query(predicate: ::TERMS[:ual].fedora3UUID)
        fedora3uuid = object_value(fedora3uuid_query) if fedora3uuid_query.count > 0
        creators_query = graph.query(predicate: ::RDF::Vocab::DC11.creator)
        creators = object_value(creators_query) if creators_query.count > 0
        creators.map!(&:value) if creators.is_a? Array
        owner_query = graph.query(predicate: ::TERMS[:bibo].owner)
        owner = object_value(owner_query) if owner_query.count > 0
        community = Community.new_locked_ldp_object(title: title, description: description,
                                                    fedora3_uuid: fedora3uuid, owner: user_id(owner),
                                                    creators: creators)
        community.unlock_and_fetch_ldp_object(&:save!)
        puts "#{community.id}:#{hydra_noid}"
        f.write "#{community.id}:#{hydra_noid}\n"
      end
    end
  end

  def migrate_collections(dir)
    File.open('collections.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        title_query = graph.query(predicate: ::RDF::Vocab::DC.title)
        title = object_value(title_query) if title_query.count > 0
        hydra_noid_query = graph.query(predicate: ::TERMS[:ual].hydraNoid)
        hydra_noid = object_value(hydra_noid_query) if hydra_noid_query.count > 0
        description_query = graph.query(predicate: ::RDF::Vocab::DC.description)
        description = object_value(description_query) if description_query.count > 0
        fedora3uuid_query = graph.query(predicate: ::TERMS[:ual].fedora3UUID)
        fedora3uuid = object_value(fedora3uuid_query) if fedora3uuid_query.count > 0
        creators_query = graph.query(predicate: ::RDF::Vocab::DC11.creator)
        creators = object_value(creators_query) if creators_query.count > 0
        creators.map!(&:value) if creators.is_a? Array
        owner_query = graph.query(predicate: ::TERMS[:bibo].owner)
        owner = object_value(owner_query) if owner_query.count > 0
        community_query = graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)
        community_uri = object_value(community_query) if community_query.count > 0
        community_hash = community_collection_hash('communities.txt')
        if community_uri.nil?
          puts "#{hydra_noid} don't have community"
        else
          community_noid = community_uri.split('/')[-1] unless community_uri.nil?
          community_id = community_hash[community_noid]
          collection = Collection.new_locked_ldp_object(title: title, description: description,
                                                        fedora3_uuid: fedora3uuid, owner: user_id(owner),
                                                        creators: creators, community_id: community_id)
          collection.unlock_and_fetch_ldp_object(&:save!)
          puts "#{collection.id}:#{hydra_noid}:#{community_id}"
          f.write "#{collection.id}:#{hydra_noid}:#{community_id}\n"
        end
      end
    end
  end

  def migrate_items(dir)
    collection_hash = community_collection_hash('collections.txt')
    collection_community = collection_parent_hash('collections.txt')
    File.open('generic.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file

        title_query = graph.query(predicate: ::RDF::Vocab::DC.title)
        title = object_value(title_query) if title_query.count > 0

        hydra_noid_query = graph.query(predicate: ::TERMS[:ual].hydraNoid)
        hydra_noid = object_value(hydra_noid_query) if hydra_noid_query.count > 0

        description_query = graph.query(predicate: ::RDF::Vocab::DC.description)
        description = object_value(description_query) if description_query.count > 0

        fedora3uuid_query = graph.query(predicate: ::TERMS[:ual].fedora3UUID)
        fedora3uuid = object_value(fedora3uuid_query) if fedora3uuid_query.count > 0

        creators_query = graph.query(predicate: ::RDF::Vocab::DC11.creator)
        creators = object_value(creators_query) if creators_query.count > 0
        creators.map!(&:value) if creators.is_a? Array
        creators = [creators] if creators.is_a? String

        owner_query = graph.query(predicate: ::TERMS[:bibo].owner)
        owner = object_value(owner_query) if owner_query.count > 0
        if owner.is_a? Array
          owner.map!(&:value)
          owner = owner.sort.first
        end

        depositor = object_value(graph.query(predicate: ::TERMS[:ual].depositor))

        owner = depositor if owner.nil?
        contributors = object_value(graph.query(predicate: ::RDF::Vocab::DC11.contributor))
        created = object_value(graph.query(predicate: ::RDF::Vocab::DC.created))
        sort_year = object_value(graph.query(predicate: ::TERMS[:ual].sortyear))
        subject_query = graph.query(predicate: ::RDF::Vocab::DC11.subject)
        subject = object_value(subject_query) if subject_query.count > 0
        subject = multiple_value(subject)
        temporal_subjects_query = graph.query(predicate: ::RDF::Vocab::DC.temporal)
        temporal_subjects = object_value(temporal_subjects_query) if temporal_subjects_query.count > 0
        temporal_subjects = multiple_value(temporal_subjects)
        spatial_subjects_query = graph.query(predicate: ::RDF::Vocab::DC.spatial)
        spatial_subjects = object_value(spatial_subjects_query) if spatial_subjects_query.count > 0
        spatial_subjects = multiple_value(spatial_subjects)

        publisher = object_value(graph.query(predicate: ::RDF::Vocab::DC.publisher))
        language = object_value(graph.query(predicate: ::RDF::Vocab::DC.language))

        embargo_end_date = object_value(graph.query(predicate: ::RDF::Vocab::DC.available))
        license = object_value(graph.query(predicate: ::RDF::Vocab::DC.license))

        rights = object_value(graph.query(predicate: ::RDF::Vocab::DC11.rights))
        item_type = object_value(graph.query(predicate: ::RDF::Vocab::DC.type))
        publication_status = object_value(graph.query(predicate: ::TERMS[:bibo].status))

        derived_from = object_value(graph.query(predicate: ::RDF::Vocab::DC.source))
        is_version_of = object_value(graph.query(predicate: ::RDF::Vocab::DC.isVersionOf))
        is_version_of = multiple_value(is_version_of)
        alternative_title = object_value(graph.query(predicate: ::RDF::Vocab::DC.alternative))
        related_link = object_value(graph.query(predicate: ::RDF::Vocab::DC.relation))
        fedora3handle = object_value(graph.query(predicate: ::TERMS[:ual].fedora3handle))
        doi = object_value(graph.query(predicate: ::TERMS[:prism].doi))
        embargo_history = object_value(graph.query(predicate: ::TERMS[:acl].embargoHistory))
        embargo_history = multiple_value(embargo_history)
        visibility_after_embargo = object_value(graph.query(predicate: ::TERMS[:acl].visibilityAfterEmbargo))
        visibility = object_value(graph.query(predicate: ::RDF::Vocab::DC.accessRights))
        visibility = JupiterCore::VISIBILITY_PUBLIC if visibility.nil?
        collection_query = graph.query(predicate: ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)
        collection_uri = object_value(collection_query) if collection_query.count > 0

        if collection_uri.nil?
          puts "#{hydra_noid} do not have a collection"
        else
          collection_noid = collection_uri.split('/')[-1] unless collection_uri.nil?
          collection_id = collection_hash[collection_noid]
          community_id = collection_community[collection_noid]
          path = "#{community_id}/#{collection_id}"
        end
        file_dir = "tmp/#{hydra_noid}"
        `mkdir -p #{file_dir} && cd #{file_dir} &&
         wget --content-disposition -q -N https://era.library.ualberta.ca/downloads/#{hydra_noid}`
        files = Dir["#{file_dir}/*"]
        puts "path is #{path}"
        if path.nil? || path.blank? || path == '/'
          puts "#{hydra_noid} don't have community/collection"
        else
          item = Item.new_locked_ldp_object(title: title, creators: creators, contributors: contributors,
                                            description: description, created: created, sort_year: sort_year,
                                            temporal_subjects: temporal_subjects, spatial_subjects: spatial_subjects,
                                            subject: subject, publisher: publisher, languages: [language],
                                            license: license, rights: rights,
                                            item_type: item_type, publication_status: publication_status,
                                            derived_from: derived_from, is_version_of: is_version_of,
                                            alternative_title: alternative_title, related_link: related_link,
                                            embargo_end_date: embargo_end_date, embargo_history: embargo_history,
                                            visibility_after_embargo: visibility_after_embargo,
                                            depositor: depositor, owner: user_id(owner), visibility: visibility,
                                            fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                            member_of_paths: [path], doi: doi)

          item.unlock_and_fetch_ldp_object(&:save!)
          unless files.empty?
            File.open(files.first) do |uploaded_file|
              item.unlock_and_fetch_ldp_object do |uo|
                uo.add_files([uploaded_file])
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
end
