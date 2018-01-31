# set credentials to access fedora
FEDORA_BASE = ''.freeze
FEDORA_USER = ''.freeze
FEDORA_PASS = ''.freeze

TARGET_FEDORA_BASE = ''.freeze

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
    result = find_by(noid: noid)
    return true if result.present?
    false
  end

  def find_by_noid(noid)
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

  def user_id(owner)
    # this requires a user file from current hydranorth, in this format: email|display_name|firstname lastname|username|ccid
    # file name: users.txt
    l = if owner.include? 'hydranorth.ca'
          File.foreach('users.txt').grep(/\|#{owner[/[^@]+/]}\|/)
        else
          File.foreach('users.txt').grep(/^#{owner}/)
        end
    if l.present?
      ccid = l.first.split('|')[4].strip
      name = l.first.split('|')[1].strip
    end
    ccid = owner[/[^@]+/] if ccid.blank?
    owner = ccid + '@ualberta.ca'
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
    File.open('communities.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)
        next if find_duplicates(hydra_noid)
        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner)
        community = Community.new_locked_ldp_object(title: title, description: description,
                                                    fedora3_uuid: fedora3uuid, owner: user_id(owner),
                                                    creators: creators, hydra_noid: hydra_noid)
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
        next if find_duplicates(hydra_noid)
        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)
        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner)
        community = object_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.memberOf)
        if community.nil?
          Rails.logger.error "collection #{hydra_noid} don't have community in HydraNorth"
          next
        else
          community_noid = community.split('/')[-1] unless community.nil?
          community_id = find_by(noid: community_noid)
          if community_id.nil?
            Rails.logger.error "collection #{hydra_noid}'s community #{community_noid} hasn't been migrated"
            next
          else
            collection = Collection.new_locked_ldp_object(title: title, description: description,
                                                          fedora3_uuid: fedora3uuid, owner: user_id(owner),
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
    collection_ids = []
    if collections.nil?
      Rails.logger.error "#{hydra_noid} do not have a collection"
    else
      collections.each do |c|
        noid = c.split('/')[-1]
        collection_id = find_by(noid: noid)
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
    File.open('generic.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)
        next if find_duplicates(hydra_noid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        description = object_value_from_predicate(graph, ::RDF::Vocab::DC.description)

        creators = object_value_from_predicate(graph, ::RDF::Vocab::DC11.creator, true)&.map! { |c| c.value }
        owner = object_value_from_predicate(graph, ::TERMS[:bibo].owner, true)&.map! { |c| c.value }
        # This is to assume the first owner of any multi-owner items becomes the sole owner of the object. Need review
        owner = owner.sort.first if owner.is_a? Array
        depositor = object_value_from_predicate(graph, ::TERMS[:ual].depositor)
        # if there is no owner, use the depositor as the owner
        owner = depositor if owner.nil?
        contributors = object_value_from_predicate(graph, ::RDF::Vocab::DC11.contributor, true)&.map! { |c| c.value }

        created = object_value_from_predicate(graph, ::RDF::Vocab::DC.created)
        sort_year = object_value_from_predicate(graph, ::TERMS[:ual].sortyear)

        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject, true)&.map! { |c| c.value }
        temporal_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.temporal, true)&.map! { |c| c.value }
        spatial_subjects = object_value_from_predicate(graph, ::RDF::Vocab::DC.spatial, true)&.map! { |c| c.value }

        publisher = object_value_from_predicate(graph, ::RDF::Vocab::DC.publisher)
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargoHistory, true)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibilityAfterEmbargo)
        visibility = object_value_from_predicate(graph, ::RDF::Vocab::DC.accessRights)
        visibility = 'http://terms.library.ualberta.ca/public' if visibility.nil?
        visibility_after_embargo = nil if visibility != 'http://terms.library.ualberta.ca/embargo'

        license = object_value_from_predicate(graph, ::RDF::Vocab::DC.license)
        rights = object_value_from_predicate(graph, ::RDF::Vocab::DC11.rights)
        rights = remove_incomplete_rights(rights) if rights.is_a?(Array)

        item_type = object_value_from_predicate(graph, ::RDF::Vocab::DC.type)
        publication_status = object_value_from_predicate(graph, ::TERMS[:bibo].status, true)&.map! { |c| c.value }
        derived_from = object_value_from_predicate(graph, ::RDF::Vocab::DC.source)
        is_version_of = object_value_from_predicate(graph, ::RDF::Vocab::DC.isVersionOf, true)&.map! { |c| c.value }
        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)
        related_link = object_value_from_predicate(graph, ::RDF::Vocab::DC.relation)

        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)

        collection_ids = get_collections(graph)
        community_ids = get_communities(collection_ids) unless collection_ids.empty?

        if collection_ids.empty? && community_ids.empty?
          puts "#{hydra_noid} don't have community/collection"
          Rails.logger.error "can't find #{hydra_noid}'s collection or community"
        else
          owner = user_id(owner)

          file_dir = "tmp/#{hydra_noid}"
          download_url = FEDORA_BASE + pairtree(hydra_noid) + '/content'
          download_file(download_url, file_dir)
          if File.exist?("#{file_dir}/#{hydra_noid}.zip") || File.exist?("#{file_dir}/#{fedora3uuid}.zip")
            `unzip #{file_dir}/*.zip -d #{file_dir} && rm #{file_dir}/*.zip`
          end
          files = Dir.glob("#{file_dir}/**/*").select { |uf| File.file?(uf) }.sort&.map! { |uf| File.open(uf) }
          begin
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
                                              depositor: depositor, owner: owner, visibility: visibility,
                                              fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                              doi: doi, hydra_noid: hydra_noid)
            item.unlock_and_fetch_ldp_object do |unlocked_item|
              unlocked_item.add_communities_and_collections(community_ids, collection_ids)
              if files.empty?
                Rails.logger.error "#{hydra_noid}'s file can't be unloaded"
              else
                unlocked_item.add_files(files)

                `rm -rf #{file_dir}`
              end
              unlocked_item.save!
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

  def migrate_theses(dir)
    File.open('theses.txt', 'w+') do |f|
      Dir[dir + '/*.nt'].each do |file|
        graph = RDF::Graph.load file
        hydra_noid = object_value_from_predicate(graph, ::TERMS[:ual].hydraNoid)
        next if find_duplicates(hydra_noid)

        title = object_value_from_predicate(graph, ::RDF::Vocab::DC.title)
        institution = object_value_from_predicate(graph, ::TERMS[:swrc].institution)
        abstract = object_value_from_predicate(graph, ::RDF::Vocab::DC.abstract)
        date_accepted = object_value_from_predicate(graph, ::RDF::Vocab::DC.dateAccepted)
        date_submitted = object_value_from_predicate(graph, ::RDF::Vocab::DC.dateSubmitted)
        degree = object_value_from_predicate(graph, ::RDF::Vocab::BIBO.degree)
        dissertant = object_value_from_predicate(graph, ::TERMS[:ual].dissertant)
        owner = user_id('eraadmi@ualberta.ca')

        depositor = object_value_from_predicate(graph, ::TERMS[:ual].depositor)

        graduation_date = object_value_from_predicate(graph, ::TERMS[:ual].graduationDate)
        thesis_level = object_value_from_predicate(graph, ::TERMS[:ual].thesisLevel)
        committee_members = 
          object_value_from_predicate(graph, ::TERMS[:ual].committeeMember, true)&.map! { |c| c.value }
        departments = object_value_from_predicate(graph, ::TERMS[:ual].department, true)&.map! { |c| c.value }
        specializations = object_value_from_predicate(graph, ::TERMS[:ual].specialization, true)&.map! { |c| c.value }
        supervisors = object_value_from_predicate(graph, ::TERMS[:ual].supervisor, true)&.map! { |c| c.value }
        language = object_value_from_predicate(graph, ::RDF::Vocab::DC.language)

        embargo_end_date = object_value_from_predicate(graph, ::RDF::Vocab::DC.available)
        embargo_history = object_value_from_predicate(graph, ::TERMS[:acl].embargoHistory, true)&.map! { |c| c.value }
        visibility_after_embargo = object_value_from_predicate(graph, ::TERMS[:acl].visibilityAfterEmbargo)
        visibility = object_value_from_predicate(graph, ::RDF::Vocab::DC.accessRights)
        visibility = 'http://terms.library.ualberta.ca/public' if visibility.nil?
        visibility_after_embargo = nil if visibility != 'http://terms.library.ualberta.ca/embargo'

        rights = 'This thesis is made available by the University of Alberta Libraries with permission of the copyright owner solely for non-commercial purposes. This thesis, or any portion thereof, may not otherwise be copied or reproduced without the written consent of the copyright owner, except to the extent permitted by Canadian copyright law.'
        item_type = object_value_from_predicate(graph, ::RDF::Vocab::DC.type)
        subject = object_value_from_predicate(graph, ::RDF::Vocab::DC11.subject, true)&.map! { |c| c.value }

        alternative_title = object_value_from_predicate(graph, ::RDF::Vocab::DC.alternative)

        fedora3uuid = object_value_from_predicate(graph, ::TERMS[:ual].fedora3UUID)
        fedora3handle = object_value_from_predicate(graph, ::TERMS[:ual].fedora3handle)
        doi = object_value_from_predicate(graph, ::TERMS[:prism].doi)
        proquest = object_value_from_predicate(graph, ::TERMS[:ual].proquest)
        unicorn =  object_value_from_predicate(graph, ::TERMS[:ual].unicorn)

        collection_ids = get_collections(graph)
        community_ids = get_communities(collection_ids) unless collection_ids.empty?

        if collection_ids.empty? && community_ids.empty?
          puts "#{hydra_noid} don't have community/collection"
          Rails.logger.error "can't find #{hydra_noid}'s collection or community"
        else
          file_dir = "tmp/#{hydra_noid}"
          download_url = FEDORA_BASE + pairtree(hydra_noid) + '/content'
          download_file(download_url, file_dir)
          if File.exist?("#{file_dir}/#{hydra_noid}.zip") || File.exist?("#{file_dir}/#{fedora3uuid}.zip")
            `unzip #{file_dir}/*.zip -d #{file_dir} && rm #{file_dir}/*.zip`
          end
          files = Dir.glob("#{file_dir}/**/*").select { |uf| File.file?(uf) }.sort&.map! { |uf| File.open(uf) }
          begin
            item = Item.new_locked_ldp_object(title: title, dissertant: dissertant, degree: degree,
                                              abstract: abstract, date_accepted: date_accepted,
                                              date_submitted: date_submitted, institution: institution,
                                              graduation_date: graduation_date, thesis_level: thesis_level,
                                              committee_members: committee_members, departments: departments,
                                              subject: subject, specializations: specializations,
                                              supervisors: supervisors, language: language,
                                              rights: rights, item_type: item_type,
                                              alternative_title: alternative_title,
                                              embargo_end_date: embargo_end_date, embargo_history: embargo_history,
                                              visibility_after_embargo: visibility_after_embargo,
                                              depositor: depositor, owner: owner, visibility: visibility,
                                              fedora3_uuid: fedora3uuid, fedora3_handle: fedora3handle,
                                              doi: doi, proquest: proquest, unicorn: unicorn, hydra_noid: hydra_noid)
            item.unlock_and_fetch_ldp_object do |unlocked_item|
              unlocked_item.add_communities_and_collections(community_ids, collection_ids)
              if files.empty?
                Rails.logger.error "#{hydra_noid}'s file can't be unloaded"
              else
                unlocked_item.add_files(files)

                `rm -rf #{file_dir}`
              end
              unlocked_item.save!
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

  # Methods for migrating related_objects (era1stats, and foxml files from previous versions of ERA as separate related_objects to the main record)
  def subject_value_from_predicate(graph, predicate)
    query_results = graph.query(predicate: predicate)
    values = query_results.enum_subject.to_a
    return nil if values.count == 0
    values
  end

  def create_related_object(type, main_noid)
    main_id = find_by(noid: main_noid)
    main_uri = TARGET_FEDORA_BASE + pairtree(main_id)
    file_dir = "tmp/#{main_noid}"
    file_url = FEDORA_BASE + pairtree(main_noid) + '/' + type
    download_file(file_url, file_dir)
    if type == 'fedora3foxml'
      file = Dir.glob("#{file_dir}/uuid_*.xml")
    elsif type == 'era1stats'
      file = Dir.glob("#{file_dir}/#{main_noid}.txt")
    end
    begin
      RelatedObject.new(related_to: main_uri) do |r|
        r.add_file(File.open(file))
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
        main_id = find_by(noid: main_noid)
        next if main_id.blank?
        Rails.logger.error "Issue with #{main_noid}, not returning #{main_id}" if main_id.blank?

        related_objects = subject_value_from_predicate(graph, ::Hydra::PCDM::Vocab::PCDMTerms.relatedObjectOf)

        related_objects.each do |t|
          type = t.value.split('/')[-1]
          id = create_related_object(type, main_noid)
          f.write("#{main_noid}:#{main_id}:#{id}:#{type}")
          puts "#{main_noid}:#{main_id}:#{id}:#{type}"
        end
      end
    end
  end
end
