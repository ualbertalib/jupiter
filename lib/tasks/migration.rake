# Need to set following credentials:
# FEDORA_BASE -> hydranorth's fedora base url
# FEDORA_USER -> hydranorth's fedora user
# FEDORA_PASS -> hydranorth's fedora password
# TARGET_FEDORA_BASE -> jupiter's fedora base url

THESIS_RIGHTS = "This thesis is made available by the University of Alberta Libraries with permission of the copyright owner solely for non-commercial purposes. This thesis, or any portion thereof, may not otherwise be copied or reproduced without the written consent of the copyright owner, except to the extent permitted by Canadian copyright law.".freeze

namespace :migration do
  desc 'migrate objects to jupiter'
  task :objects, [:type, :dir] => :environment do |_t, args|
    begin
      type = args.type
      dir = args.dir
      Rails.logger.info "START: Migrate #{type} from #{dir}"
      if File.exist?(dir) && File.directory?(dir)
        case type
        when 'community'
          migrate_communities(dir)
        when 'collection'
          migrate_collections(dir)
        when 'item'
          migrate_items(dir)
        when 'draft'
          migrate_draft_items(dir)
        when 'related'
          migrate_related_objects(dir)
        when 'thesis'
          migrate_theses(dir)
        else
          Rails.logger.error "Invalid migration type #{type}"
        end
      else
        Rails.logger.error "Invalid directory #{dir}"
      end
      Rails.logger.info "FINISHED: Migrate #{type} from #{dir}"
    rescue StandardError
      raise
    end
  end

  def find_duplicates(noid)
    result = find_object_by_noid(noid)
    return true if result.present?
    false
  end

  def find_object_by_noid(noid)
    result = ActiveFedora::SolrService.instance.conn.get 'select', params: { q: "hydra_noid_ssim:#{noid}", fl: 'id' }
    return result['response']['docs'].first['id'] if result['response']['numFound'] == 1
    Rails.logger.error "Duplicates found #{noid}" if result['response']['numFound'] > 1
    nil
  end

  def find_community(collection_id)
    collection = Collection.find(collection_id)
    return collection.community_id if collection.present?
    return
  rescue JupiterCore::ObjectNotFound
    Rails.logger.error "Given ID: #{collection_id} is a community." unless Community.find(collection_id).nil?
    Rails.logger.error "Can't find collection #{collection_id}"
  end

  def load_users(user_file)
    # this requires a user file from current hydranorth, in this format: email|display_name|ccid
    # file name: users.txt
    users = {}
    File.open(user_file).each_line do |l|
      data = l.strip.split("|")
      users[data[0]] = [data[1], data[2]]
    end
    return users
  end

  def user_id(users,owner)
    owner = owner.first if (owner.is_a? Array) && owner.size == 1
    l = if owner.include? 'hydranorth.ca'
          users[owner.split("@")[0]+"@ualberta.ca"]
        else
          users[owner]
        end
    if l.present?
      ccid = l[1]
      name = l[0]
    end
    ccid = owner[/[^@]+/] if ccid.blank? && owner.include?("ualberta.ca")
    owner = ccid + '@ualberta.ca' if ccid.present?
    user = User.find_or_create_by(email: owner) do |u|
      u.name = if name.present?
                 name
               else
                 ccid
               end
      u.save!
    end
    user.id
  end

  def remove_incomplete_rights(rights)
    rights = rights&.map! { |c| c.value }
    return rights.max_by(&:length) if rights.max_by(&:length).include? rights.min_by(&:length).split('...')[0]
  end

  def object_value_from_predicate(graph, predicate, multivalue = false)
    query_results = graph.query(predicate: predicate)
    values = query_results.enum_object.to_a
    return nil if values.count == 0
    return values if values.count == 1 && multivalue
    return values.first.to_s if values.count == 1 && !multivalue
    return values if values.count > 1
  end

  def pairtree(id)
    "#{id[0..1]}/#{id[2..3]}/#{id[4..5]}/#{id[6..7]}/#{id}"
  end

  def download_file(download_url, target_path)
    uri = URI(download_url)
    user = FEDORA_USER
    password = FEDORA_PASS

    request = Net::HTTP::Get.new(uri)
    request.basic_auth(user, password)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    begin
      if response.is_a?(Net::HTTPSuccess)
        filename = response.to_hash['content-disposition'].first.split('; ')[1].split('=')[1].delete!('"')
        Dir.mkdir(target_path) unless File.exist?(target_path)
        basename = filename.rpartition('/').last
        file = File.open(target_path + '/' + basename, 'wb')
        file.write(response.body)
        file.close
        return true
      elsif response.is_a?(Net::HTTPNotFound)
        Rails.logger.error "#{download_url.split('/')[-2]} file not found"
        return false
      else
        Rails.logger.error "Problem occurs when download #{download_url}"
      end
    rescue StandardError => e
      Rails.logger.error "Problem occurs when download #{download_url}: #{e}"
    end
  end

  def migrate_communities(dir)
    users = load_users('users.txt')
    File.open('communities.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
        next if find_duplicates(hydra_noid)
        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_uuid)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.owner)
        community = Community.new_locked_ldp_object(title: title, description: description,
                                                    fedora3_uuid: fedora3uuid, owner: user_id(users, owner),
                                                    creators: creators, hydra_noid: hydra_noid)
        community.unlock_and_fetch_ldp_object(&:save!)
        puts "#{community.id}:#{hydra_noid}"
        f.write "#{community.id}:#{hydra_noid}\n"
      end
    end
  end

  def migrate_collections(dir)
    users = load_users('users.txt')
    File.open('collections.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
        next if find_duplicates(hydra_noid)
        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_uuid)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.owner)
        community = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)

        # 2018-04-04 if no community, use temporary community
        if community.nil?
          Rails.logger.info "collection #{hydra_noid} to temp comm; was comm: #{community}"
          community = 'dummycomm'
        end

        if community.nil?
          Rails.logger.error "collection #{hydra_noid} don't have community in HydraNorth"
          next
        else
          community_noid = community.split('/')[-1] unless community.nil?
          community_id = find_object_by_noid(community_noid)
          if community_id.nil?
            Rails.logger.error "collection #{hydra_noid}'s community #{community_noid} hasn't been migrated"
            next
          else
            collection = Collection.new_locked_ldp_object(title: title, description: description,
                                                          fedora3_uuid: fedora3uuid, owner: user_id(users,owner),
                                                          creators: creators, community_id: community_id,
                                                          hydra_noid: hydra_noid)
            collection.unlock_and_fetch_ldp_object(&:save!)
            puts "#{collection.id}:#{hydra_noid}:#{community_id}"
            f.write "#{collection.id}:#{hydra_noid}:#{community_id}\n"
          end
        end
      end
    end
  end

  def get_collections(graph)
    collections = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.memberOf,
                                              true)&.map! { |c| c.value }
    hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
    collection_ids = []
    if collections.nil?
      Rails.logger.error "#{hydra_noid} do not have a collection"
    else
      collections.each do |c|
        noid = c.split('/')[-1]
        collection_id = find_object_by_noid(noid)
        collection_ids << collection_id if collection_id.present?
      end
    end
    collection_ids
  end

  def get_communities(collection_ids)
    community_ids = []
    collection_ids.each do |c|
      community_ids <<  find_community(c)
    end
    community_ids
  end

  def migrate_items(dir)
    users = load_users('users.txt')
    File.open('generic.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        #sleep(10)
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
        dupe = find_duplicates(hydra_noid)
        if dupe
	    dupes = dir + '/dupes/'
            Dir.mkdir(dupes) unless File.exist?(dupes)
            `mv #{dir}/#{File.basename(file)} #{dupes}`
        end 
	next if dupe

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)

        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.owner, true)&.map! { |c| c.value }
        # Here are some logic based on Leah's understanding of the actual ownership for multi-owner objects
     
        depositor = object_value_from_predicate(graph, ::TERMS[:ual].depositor)
	# insert here for multiowner rules

        # if there is no owner, use the depositor as the owner
        owner = depositor if owner.nil?
        contributors = object_value_from_predicate(graph, ::RDF::Vocab::DC11.contributor, true)&.map! { |c| c.value }

        created = object_value_from_predicate(graph, ::RDF::Vocab::DC.created)
        #sort_year = object_value_from_predicate(graph, ::TERMS[:ual].sort_year)
        sort_year = 1500

        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject, true)&.map! { |c| c.value }
        temporal_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.temporal, true)&.map! { |c| c.value }
        spatial_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.spatial, true)&.map! { |c| c.value }

        publisher = object_value_from_predicate(graph, ::RDF::Vocab::DC.publisher)
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargo_history, true)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibility_after_embargo)
        visibility = object_value_from_predicate(graph, ::RDF::Vocab::DC.accessRights)
        visibility = 'http://terms.library.ualberta.ca/public' if visibility.nil?
        visibility_after_embargo = nil if visibility != 'http://terms.library.ualberta.ca/embargo'

        license = object_value_from_predicate(graph, ::RDF::Vocab::DC.license)
        rights = object_value_from_predicate(graph, ::RDF::Vocab::DC11.rights)
        rights = remove_incomplete_rights(rights) if rights.is_a?(Array)

        item_type = object_value_from_predicate(graph, ::RDF::Vocab::DC.type)
        publication_status = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.status, true)&.map! { |c| c.value }
        source = object_value_from_predicate(graph, ::RDF::Vocab::DC.source)
        is_version_of = object_value_from_predicate(graph, ::RDF::Vocab::DC.isVersionOf, true)&.map! { |c| c.value }
        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)
        related_link = object_value_from_predicate(graph, ::RDF::Vocab::DC.relation)

        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_uuid)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)
        ingest_batch = object_value_from_predicate(graph, ::TERMS[:ual].ingest_batch)
        nna_file = object_value_from_predicate(graph, ::TERMS[:ual].northern_north_america_filename)
        nna_item = object_value_from_predicate(graph, ::TERMS[:ual].northern_north_america_item_id)


        collection_ids = get_collections(graph)
        community_ids = get_communities(collection_ids) unless collection_ids.empty?

        # 2018-04-04 if no community, use temporary community
        if collection_ids.nil? || community_ids.nil?
          Rails.logger.info "item #{hydra_noid} to temp comm/coll; was comm: #{community_ids}, coll: #{collection_ids}"
          community_ids = ['b50523c6-5037-40a0-b511-10aa6b17fe12']
          collection_ids = ['aa85eae2-cfdb-4eff-9be9-816f0dd358f0']
        end


        if collection_ids.nil? && community_ids.nil?
          puts "#{hydra_noid} don't have community/collection"
          Rails.logger.error "can't find #{hydra_noid}'s collection or community"
        else

          begin 
            owner = user_id(users, owner)

            file_dir = "tmp/migration/#{hydra_noid}"
            download_url = FEDORA_BASE + pairtree(hydra_noid) + '/content'
            download_file(download_url, file_dir)
            if File.exist?("#{file_dir}/#{hydra_noid}.zip") || File.exist?("#{file_dir}/#{fedora3uuid}.zip")
              `unzip -o #{file_dir}/*.zip -d #{file_dir} && rm #{file_dir}/*.zip`
            end
            files = Dir.glob("#{file_dir}/**/*").select { |uf| File.file?(uf) }.sort&.map! { |uf| File.open(uf) }
            item = Item.new_locked_ldp_object(title: title, creators: creators, unordered_creators: creators, 
                                              contributors: contributors,
                                              description: description, created: created, sort_year: sort_year,
                                              temporal_subjects: temporal_subjects, spatial_subjects: spatial_subjects,
                                              subject: subject, publisher: publisher, languages: [language],
                                              license: license, rights: rights,
                                              item_type: item_type, publication_status: publication_status,
                                              source: source, is_version_of: is_version_of,
                                              alternative_title: alternative_title, related_link: related_link,
                                              embargo_end_date: embargo_end_date, embargo_history: embargo_history,
                                              visibility_after_embargo: visibility_after_embargo,
                                              depositor: depositor, owner: owner, visibility: visibility,
                                              fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                              doi: doi, hydra_noid: hydra_noid, ingest_batch: ingest_batch, northern_north_america_filename: nna_file,
                                              northern_north_america_item_id: nna_item)

            item.unlock_and_fetch_ldp_object do |unlocked_item|
              unlocked_item.add_communities_and_collections(community_ids, collection_ids)
              if files.empty?
                Rails.logger.error "#{hydra_noid}'s file can't be uploaded"
              else
                unlocked_item.add_files(files)

                `rm -rf #{file_dir}`
              end
              unlocked_item.save!
              item.thumbnail_fileset(item.file_sets.first) unless item.file_sets.first.contained_filename.end_with? 'xlsx'
            end
            puts "#{item.id}:#{hydra_noid}"
            f.write "#{item.id}:#{hydra_noid}\n"
            completed = dir + '/completed/'
            Dir.mkdir(completed) unless File.exist?(completed)
            `mv #{dir}/#{File.basename(file)} #{completed}`
          rescue ActiveFedora::RecordInvalid => e
            Rails.logger.error "#{hydra_noid}'s metadata is invalid, #{e}"
            `mv #{dir}/#{File.basename(file)} problem`
          rescue StandardError => e
            Rails.logger.error "#{hydra_noid}'s migration failed due to error: #{e}"
            `mv #{dir}/#{File.basename(file)} problem`
          end
        end
      end
    end
  end

# You can reuse this entirely

# https://github.com/ualbertalib/jupiter/blob/a8a90b2133d259e1b0f690daa965c387ffd380d8/lib/tasks/migration.rake#L228-L349

# Instead of using a draft visibility from # https://github.com/ualbertalib/jupiter/blob/a8a90b2133d259e1b0f690daa965c387ffd380d8/lib/tasks/migration.rake#L264, set the # visibility to public here
# (it won't _be_ public, this will just be the value selected when the user edits the draft)

# but then instead of calling save here: 

# https://github.com/ualbertalib/jupiter/blob/a8a90b2133d259e1b0f690daa965c387ffd380d8/lib/tasks/migration.rake#L331

# call 

# DraftItem.create(user: owner).update_from_fedora_item(item, owner)

# Net result would be:

  def migrate_draft_items(dir)
    users = load_users('users.txt')
    File.open('drafts.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        #sleep(10)
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
        next if find_duplicates(hydra_noid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)

        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.owner, true)&.map! { |c| c.value }
        # Here are some logic based on Leah's understanding of the actual ownership for multi-owner objects

        depositor = object_value_from_predicate(graph, ::TERMS[:ual].depositor)
  # insert here for multiowner rules

        admins = ["erahelp@ualberta.ca", "piyapong.charoenwattana@ualberta.ca", "dit.application.test@ualberta.ca", 
          "riedlber@ualberta.ca", "era@ualberta.ca", "abombak@ualberta.ca"]
 
         if owner.present? && owner.size > 1
           owner.map { |x| (admins.include? x)  ? 'eraadmi@ualberta.ca' : x } 
           owner = 'gapsshrc@ualberta.ca' if owner.include? 'gapsshrc@ualberta.ca'
           owner = 'sandy.campbell@ualberta.ca' if owner.include? 'sandy.campbell@ualberta.ca'
           owner = 'csweb@ualberta.ca' if owner.include? 'csweb@ualberta.ca'
           owner = 'eraadmi@ualberta.ca' if owner.include? 'fip@ualberta.ca'
           owner = 'joanne.simala-grant@ualberta.ca' if owner.include? 'cihrgrants@ualberta.ca'
           owner = 'joanne.simala-grant@ualberta.ca' if owner.include? 'helencoe@med.ualberta.ca'
           owner = 'noriko.hessmann@ualberta.ca' if owner.include? 'noriko.hessmann@ualberta.ca'
           # This is to assume that if the depositor is not admin, the depositor info will take precedent other than the cases above
           owner = depositor if owner.is_a?(Array) && depositor != 'eraadmi@ualberta.ca'
           # If owners are admin + other users for any remaining multi-owner items, other users will be considered as owners
           if owner.is_a? Array
             owner = owner - ['eraadmi@ualberta.ca'] if owner.is_a?(Array)
             # This is to assume the first owner of any remaining multi-owner items becomes the sole owner of the object.
             owner = owner.sort.first 
           end
         else
           owner = "eraadmi@ualberta.ca" if admins.include? owner
         end


        # if there is no owner, use the depositor as the owner
        owner = depositor if owner.nil?
        contributors = object_value_from_predicate(graph, ::RDF::Vocab::DC11.contributor, true)&.map! { |c| c.value }

        created = object_value_from_predicate(graph, ::RDF::Vocab::DC.created)
        #sort_year = object_value_from_predicate(graph, ::TERMS[:ual].sort_year)
        sort_year = 1500

        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject, true)&.map! { |c| c.value }
        temporal_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.temporal, true)&.map! { |c| c.value }
        spatial_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.spatial, true)&.map! { |c| c.value }

        publisher = object_value_from_predicate(graph, ::RDF::Vocab::DC.publisher)
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargo_history, true)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibility_after_embargo)
        visibility = 'http://terms.library.ualberta.ca/public'
        visibility_after_embargo = nil if visibility != 'http://terms.library.ualberta.ca/embargo'

        license = object_value_from_predicate(graph, ::RDF::Vocab::DC.license)
        rights = object_value_from_predicate(graph, ::RDF::Vocab::DC11.rights)
        rights = remove_incomplete_rights(rights) if rights.is_a?(Array)

        item_type = object_value_from_predicate(graph, ::RDF::Vocab::DC.type)
        publication_status = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.status, true)&.map! { |c| c.value }
        source = object_value_from_predicate(graph, ::RDF::Vocab::DC.source)
        is_version_of = object_value_from_predicate(graph, ::RDF::Vocab::DC.isVersionOf, true)&.map! { |c| c.value }
        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)
        related_link = object_value_from_predicate(graph, ::RDF::Vocab::DC.relation)

        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_uuid)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)
        ingest_batch = object_value_from_predicate(graph, ::TERMS[:ual].ingest_batch)
        nna_file = object_value_from_predicate(graph, ::TERMS[:ual].northern_north_america_filename)
        nna_item = object_value_from_predicate(graph, ::TERMS[:ual].northern_north_america_item_id)


        collection_ids = get_collections(graph)
        community_ids = get_communities(collection_ids) unless collection_ids.empty?

        # 2018-04-04 if no community, use temporary community
        if collection_ids.nil? || community_ids.nil?
          Rails.logger.info "item #{hydra_noid} to temp comm/coll; was comm: #{community_ids}, coll: #{collection_ids}"
          community_ids = ['b50523c6-5037-40a0-b511-10aa6b17fe12']
          collection_ids = ['aa85eae2-cfdb-4eff-9be9-816f0dd358f0']
        end


       if collection_ids.nil? && community_ids.nil?
          puts "#{hydra_noid} don't have community/collection"
          Rails.logger.error "can't find #{hydra_noid}'s collection or community"
        else

          begin
            owner = user_id(users, owner)

            file_dir = "tmp/migration/#{hydra_noid}"
            download_url = FEDORA_BASE + pairtree(hydra_noid) + '/content'
            download_file(download_url, file_dir)
            if File.exist?("#{file_dir}/#{hydra_noid}.zip") || File.exist?("#{file_dir}/#{fedora3uuid}.zip")
              `unzip -o #{file_dir}/*.zip -d #{file_dir} && rm #{file_dir}/*.zip`
            end
            files = Dir.glob("#{file_dir}/**/*").select { |uf| File.file?(uf) }.sort&.map! { |uf| File.open(uf) }
            item = Item.new_locked_ldp_object(title: title, creators: creators, unordered_creators: creators,
                                              contributors: contributors,
                                              description: description, created: created, sort_year: sort_year,
                                              temporal_subjects: temporal_subjects, spatial_subjects: spatial_subjects,
                                              subject: subject, publisher: publisher, languages: [language],
                                              license: license, rights: rights,
                                              item_type: item_type, publication_status: publication_status,
                                              source: source, is_version_of: is_version_of,
                                              alternative_title: alternative_title, related_link: related_link,
                                              embargo_end_date: embargo_end_date, embargo_history: embargo_history,
                                              visibility_after_embargo: visibility_after_embargo,
                                              depositor: depositor, owner: owner, visibility: visibility,
                                              fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                              doi: doi, hydra_noid: hydra_noid, ingest_batch: ingest_batch, northern_north_america_filename: nna_file,
                                              northern_north_america_item_id: nna_item)

            item.unlock_and_fetch_ldp_object do |unlocked_item|
              unlocked_item.add_communities_and_collections(community_ids, collection_ids)
            end
            owning_user = User.find(owner)
            draft_item = DraftItem.create(user: owning_user).update_from_fedora_item(item, owning_user)

            files.each do |file|
              draft_item.files.attach(io: file, filename: File.basename(file),
                                      content_type: MIME::Types.type_for(file.path).first.content_type)
            end

            if draft_item.files.empty?
              Rails.logger.error "#{hydra_noid}'s file can't be uploaded"
            else
              `rm -rf #{file_dir}`
            end

            puts "#{draft_item.id}:#{hydra_noid}"
            f.write "#{draft_item.id}:#{hydra_noid}\n"
            completed = dir + '/completed/'
            Dir.mkdir(completed) unless File.exist?(completed)
            `mv #{dir}/#{File.basename(file)} #{completed}`
          rescue ActiveFedora::RecordInvalid => e
            Rails.logger.error "#{hydra_noid}'s metadata is invalid, #{e}"
            `mv #{dir}/#{File.basename(file)} problem`
          rescue ActiveRecord::RecordInvalid => e
            Rails.logger.error "#{hydra_noid}'s metadata is invalid, #{e}"
            `mv #{dir}/#{File.basename(file)} problem`
          rescue StandardError => e
            Rails.logger.error "#{hydra_noid}'s migration failed due to error: #{e}"
            `mv #{dir}/#{File.basename(file)} problem`
          end
        end
      end
    end
  end

  def migrate_theses(dir)
    users = load_users('users.txt')
    File.open('theses.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydra_noid)
        next if find_duplicates(hydra_noid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        institution = object_value_from_predicate(graph, ::TERMS[:swrc].institution)
        abstract = object_value_from_predicate(graph, ::RDF::Vocab::DC.abstract)
        date_accepted = object_value_from_predicate(graph, ::RDF::Vocab::DC.dateAccepted)
        date_submitted = object_value_from_predicate(graph, ::RDF::Vocab::DC.dateSubmitted)
        degree = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.degree)
        dissertant = object_value_from_predicate(graph, ::TERMS[:ual].dissertant)
        owner = user_id(users, 'eraadmi@ualberta.ca')

        depositor = object_value_from_predicate(graph, ::TERMS[:ual].depositor)

        graduation_date = object_value_from_predicate(graph, ::TERMS[:ual].graduation_date)
        thesis_level = object_value_from_predicate(graph, ::TERMS[:ual].thesis_level)
        committee_members =
          object_value_from_predicate(graph, ::TERMS[:ual].committee_member, true)&.map! { |c| c.value }
        departments = object_value_from_predicate(graph, ::TERMS[:ual].department, true)&.map! { |c| c.value }
        specialization = object_value_from_predicate(graph, ::TERMS[:ual].specialization)
        supervisors = object_value_from_predicate(graph, ::TERMS[:ual].supervisor, true)&.map! { |c| c.value }
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargo_history, true)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibility_after_embargo)
        visibility = object_value_from_predicate(graph, ::RDF::Vocab::DC.accessRights)
        visibility_after_embargo = nil if visibility != 'http://terms.library.ualberta.ca/embargo'
        rights = THESIS_RIGHTS

        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject, true)&.map! { |c| c.value }

        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)

        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_uuid)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3_handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)
        proquest = object_value_from_predicate(graph, ::TERMS[:ual].proquest)
        unicorn =  object_value_from_predicate(graph, ::TERMS[:ual].unicorn)
        ingest_batch = object_value_from_predicate(graph, ::TERMS[:ual].ingest_batch)

        collection_ids = get_collections(graph)
        community_ids = get_communities(collection_ids) unless collection_ids.nil? || collection_ids.empty?
        begin 
          if collection_ids.nil? && community_ids.nil?
            puts "#{hydra_noid} don't have community/collection"
            Rails.logger.error "can't find #{hydra_noid}'s collection or community"
          else
            file_dir = "tmp/migration/#{hydra_noid}"
            download_url = FEDORA_BASE + pairtree(hydra_noid) + '/content'
            download_file(download_url, file_dir)
            if File.exist?("#{file_dir}/#{hydra_noid}.zip") || File.exist?("#{file_dir}/#{fedora3uuid}.zip")
              `unzip #{file_dir}/*.zip -d #{file_dir} && rm #{file_dir}/*.zip`
            end
            files = Dir.glob("#{file_dir}/**/*").select { |uf| File.file?(uf) }.sort&.map! { |uf| File.open(uf) }
            item = Thesis.new_locked_ldp_object(title: title, dissertant: dissertant, degree: degree,
                                                abstract: abstract, date_accepted: date_accepted,
                                                date_submitted: date_submitted, institution: institution,
                                                graduation_date: graduation_date, thesis_level: thesis_level,
                                                committee_members: committee_members, departments: departments,
                                                subject: subject, specialization: specialization,
                                                supervisors: supervisors, language: language,
                                                rights: rights, alternative_title: alternative_title,
                                                embargo_end_date: embargo_end_date, embargo_history: embargo_history,
                                                visibility_after_embargo: visibility_after_embargo,
                                                depositor: depositor, owner: owner, visibility: visibility,
                                                fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                                doi: doi, proquest: proquest, unicorn: unicorn, hydra_noid: hydra_noid,
                                                ingest_batch: ingest_batch)
            item.unlock_and_fetch_ldp_object do |unlocked_item|
              unlocked_item.add_communities_and_collections(community_ids, collection_ids)
              if files.empty?
                Rails.logger.error "#{hydra_noid}'s file can't be unloaded"
              else
                unlocked_item.add_files(files)
              end
              unlocked_item.save!
              item.thumbnail_fileset(item.file_sets.first)
              `rm -rf #{file_dir}`
            end
            puts "#{item.id}:#{hydra_noid}"
            f.write "#{item.id}:#{hydra_noid}\n"
            completed = dir + '/completed/'
            Dir.mkdir(completed) unless File.exist?(completed)
            `mv #{dir}/#{File.basename(file)} #{completed}`
          end
        rescue ActiveFedora::RecordInvalid => e
          Rails.logger.error "#{hydra_noid}'s metadata is invalid, #{e}"
          `mv #{dir}/#{File.basename(file)} problem`
        rescue StandardError => e
          Rails.logger.error "#{hydra_noid}'s migration failed due to error: #{e}"
          `mv #{dir}/#{File.basename(file)} problem`
        end
      end
    end
  end

  # Methods for migrating related_objects (era1stats, and foxml files from previous versions of ERA as separate related_objects to the main record)
  def subject_value_from_predicate(graph, predicate)
    query_results = graph.query(predicate: predicate)
    values = query_results.enum_subject.to_a
    return nil if values.count == 0
    values
  end

  def create_related_object(type, main_noid)
    main_id = find_object_by_noid(main_noid)
    main_uri = TARGET_FEDORA_BASE + pairtree(main_id)
    file_dir = "tmp/migration/#{main_noid}"
    file_url = FEDORA_BASE+ pairtree(main_noid) + '/' + type
    download_file(file_url, file_dir)
    if type == 'fedora3foxml'
      file = Dir.glob("#{file_dir}/uuid_*.xml")
    elsif type == 'era1stats'
      file = Dir.glob("#{file_dir}/#{main_noid}.txt")
    end
    begin
      RelatedObject.new(related_to: main_uri) do |r|
        r.add_file(File.open(file[0]))
        r.save!
        `rm -rf #{file_dir}`
        return r.id
      end
    rescue StandardError => e
      Rails.logger.error "#{main_noid}'s foxml can't not be migrated, #{e}"
    end
  end

  def migrate_related_objects(dir)
    File.open('related_objects.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        main_record = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.relatedObjectOf)
        main_noid = main_record.split('/')[-1]
        main_id = find_object_by_noid(main_noid)
        next if main_id.blank?
        Rails.logger.error "Issue with #{main_noid}, not returning #{main_id}" if main_id.blank?

        related_objects = subject_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.relatedObjectOf)

        related_objects.each do |t|
          type = t.value.split('/')[-1]
          id = create_related_object(type, main_noid)
          f.puts("#{main_noid}:#{main_id}:#{id}:#{type}")
          puts "#{main_noid}:#{main_id}:#{id}:#{type}"
        end
      end
    end
  end
end
