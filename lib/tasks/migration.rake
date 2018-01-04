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

  def object_value_from_predicate(graph, predicate)
    query_results = graph.query(predicate: predicate)
    values = query_results.enum_object.to_a
    return nil if values.count == 0
    return values if values.count > 0
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

  def migrate_communities(dir)
    File.open('communities.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner)
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
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)
        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner)
        community = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)
        community_hash = community_collection_hash('communities.txt')
        if community.nil?
          MigrationLogger.error "collection #{hydra_noid} don't have community"
          next
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
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner)&.map! { |c| c.value }
        # This is to assume the first owner of any multi-owner items becomes the sole owner of the object. Need review
        owner = owner.sort.first if owner.is_a? Array

        depositor = object_value_from_predicate(graph.query(predicate: ::TERMS[:ual].depositor))
        # if there is no owner, use the depositor as the owner
        owner = depositor if owner.nil?

        contributors = object_value_from_predicate(graph, ::RDF::Vocab::DC11.contributor)
        created = object_value_from_predicate(graph, ::RDF::Vocab::DC.created)
        sort_year = object_value_from_predicate(graph, ::TERMS[:ual].sortyear)
        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject)&.map! { |c| c.value }
        temporal_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.temporal)&.map! { |c| c.value }
        spatial_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.spatial)&.map! { |c| c.value }

        publisher = object_value_from_predicate(graph, ::RDF::Vocab::DC.publisher)
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        license = object_value_from_predicate(graph, ::RDF::Vocab::DC.license)

        rights = object_value_from_predicate(graph, ::RDF::Vocab::DC11.rights)
        item_type = object_value_from_predicate(graph, ::RDF::Vocab::DC.type)
        publication_status = object_value_from_predicate(graph, ::TERMS[:bibo].status)

        derived_from = object_value_from_predicate(graph, ::RDF::Vocab::DC.source)
        is_version_of = object_value_from_predicate(graph, ::RDF::Vocab::DC.isVersionOf)&.map! { |c| c.value }
        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)
        related_link = object_value_from_predicate(graph, ::RDF::Vocab::DC.relation)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargoHistory)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibilityAfterEmbargo)
        visibility = object_value_from_predicate(graph, ::RDF::Vocab::DC.accessRights) || JupiterCore::VISIBILITY_PUBLIC
        collection = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)

        if collection.nil?
          MigrationLogger.error "#{hydra_noid} do not have a collection"
        else
          collection_noid = collection.split('/')[-1] unless collection.nil?
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
