# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development? || Rails.env.uat?
  require "open-uri"
  require 'faker'

  # For the main community/collections
  THINGS = ['cat', 'dog', 'unicorn', 'hamburger', 'librarian'].freeze
  # For padding community/collection lists for pagination (need at least 26, a couple uppercase to confirm sort)
  EXTRA_THINGS = ['Library', 'DONAIR', 'magpie', 'toque', 'sombrero', 'yeti', 'mimosa', 'ukulele', 'tourtière',
                   'falafel', 'calculator', 'papusa'].freeze

  puts 'Starting seeding of dev database...'

  # start fresh
  [Announcement, ActiveStorage::Blob, ActiveStorage::Attachment,
   Identity, User, Type, Language, Institution].each(&:destroy_all)

  # Seed an admin user
  admin = User.create(name: 'Jane Admin', email: 'admin@ualberta.ca', admin: true)
  admin.identities.create(provider: 'developer', uid: 'admin@ualberta.ca')

  # Seed a non-admin user
  non_admin = User.create(name: 'Bill Non-admin', email: 'non_admin@ualberta.ca', admin: false)
  non_admin.identities.create(provider: 'developer', uid: 'non_admin@ualberta.ca')

  # Seed an suspended admin user
  bad_admin = User.create(name: 'Joe Bad-admin', email: 'bad_admin@ualberta.ca', admin: true, suspended: true)
  bad_admin.identities.create(provider: 'developer', uid: 'bad_admin@ualberta.ca')

  # Seed an suspended regular user
  bad_user = User.create(name: 'Jill Bad-user', email: 'bad_user@ualberta.ca', admin: false, suspended: true)
  bad_user.identities.create(provider: 'developer', uid: 'bad_user@ualberta.ca')

  # Seed system user for API requests
  User.create(
    email: 'ditech@ualberta.ca',
    name: 'System user',
    admin: false,
    api_key_digest: BCrypt::Password.create(
      Rails.application.secrets.system_user_api_key
    ),
    system: true
  )

  # A bunch of non-identity users for to manipulate in the admin interface
  100.times do
    name = Faker::TvShows::GameOfThrones.unique.character
    User.create(name: name, email: "#{name.gsub(/ +/, '.').downcase}@example.edu", admin: false)
  end

  # Lets pick 10 prolific creators, 10 contributors
  creators = 10.times.map { "#{Faker::Creature::Cat.unique.name} #{Faker::Creature::Cat.unique.breed.gsub(/[ ,]+/, '-')}" }
  contributors = 10.times.map { Faker::FunnyName.unique.name_with_initial }

  institutions = [CONTROLLED_VOCABULARIES[:institution].uofa, CONTROLLED_VOCABULARIES[:institution].st_stephens]

  THINGS.each_with_index do |thing, idx|
    if idx % 2 == 0
      title = "The department of #{thing.capitalize}"
    else
      title = "Special reports about #{thing.pluralize}"
    end
    community = Community.create!(
      owner_id: admin.id,
      title: title,
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
    )

    # Attach logos, if possible
    filename = File.expand_path(Rails.root + "tmp/#{thing}.png")
    unless File.exist?(filename)
      unless ENV['SKIP_DOWNLOAD_COMMUNITY_LOGOS'].present?
        set = (thing == 'cat') ? 'set4' : 'set1'
        url = Faker::Avatar.image(slug: thing, size: "100x100", format: "png", set: set)
        File.open(filename, 'wb') do |fo|
          fo.write open(url).read
        end
      end
    end
    if File.exist?(filename)
      community.logo.attach(io: File.open(filename), filename: "#{thing}.png", content_type: "image/png")
    end

    item_collection = Collection.create!(
      owner_id: admin.id,
      title: "The annals of '#{thing.capitalize} International'",
      community_id: community.id,
      description: Faker::Lorem.sentence(word_count: 40, supplemental: false, random_words_to_add: 0).chop
    )

    thesis_collection = Collection.create!(
      owner_id: admin.id,
      title: "Theses about #{thing.pluralize}",
      community_id: community.id,
      description: Faker::Lorem.sentence(word_count: 40, supplemental: false, random_words_to_add: 0).chop
    )

    # Items
    20.times do |i|
      seed = rand(10)
      seed2 = rand(10)
      base_attributes = {
        visibility: JupiterCore::VISIBILITY_PUBLIC,
        subject: [thing.capitalize],
        doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
      }
      # Add an occasional verbose description
      description = if i % 10 == 5
                      Faker::Lorem.sentence(word_count: 100, supplemental: false, random_words_to_add: 0).chop
                    else
                      Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
                    end
      # Probabilistically about 70% English, 20% French, 10% Ukrainian
      languages = if seed % 10 > 2
                    [CONTROLLED_VOCABULARIES[:language].english]
                  elsif seed % 10 > 0
                    [CONTROLLED_VOCABULARIES[:language].french]
                  else
                    [CONTROLLED_VOCABULARIES[:language].ukrainian]
                  end
      licence_right = {}

      item_attributes = base_attributes.merge({
        owner_id: admin.id,
        title: "The effects of #{Faker::Beer.name} on #{thing.pluralize}",
        created: rand(20_000).days.ago.to_s,
        creators: [creators[seed]],
        contributors: [contributors[seed2]],
        description: description,
        languages: languages,
      })

      # Add the occasional double-author work
      item_attributes[:creators] << creators[(seed + 5) % 10] if i % 7 == 3
      if seed % 10 < 6
        item_attributes[:license] = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
      elsif seed % 10 < 7
        item_attributes[:license] = CONTROLLED_VOCABULARIES[:license].public_domain_mark_1_0
      elsif seed % 10 < 8
        item_attributes[:license] = CONTROLLED_VOCABULARIES[:old_license].attribution_3_0_international
      else
        item_attributes[:rights] = 'Share my stuff with everybody'
      end
      if idx % 3 == 0
        item_attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].article
        item_attributes[:publication_status] = [CONTROLLED_VOCABULARIES[:publication_status].published]
      elsif idx % 3 == 1
        item_attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].article
        item_attributes[:publication_status] = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                           CONTROLLED_VOCABULARIES[:publication_status].submitted]
      else
        item_attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].report
      end

      # Every once in a while, create a mondo-item with full, rich metadata to help view-related work
      if i == 8
        item_attributes[:title] = item_attributes[:title].gsub(/^The/, 'The complete')
        # Throw in a second language occasionally
        item_attributes[:languages] << CONTROLLED_VOCABULARIES[:language].other
        # Why 3 and 7 below? Neither number shares a divisor with 10, ensuring a unique set
        item_attributes[:creators] += 4.times.map { |j| creators[(seed + 3 * j) % 10] }
        item_attributes[:contributors] += 3.times.map { |j| contributors[(seed2 + 7 * j) % 10] }
        item_attributes[:subject] += ['Mondo']
        item_attributes[:spatial_subjects] = ['Vegreville']
        item_attributes[:temporal_subjects] = ['1980s']
        item_attributes[:alternative_title] = "A full, holistic, #{thing}-tastic approach"
        item_attributes[:related_link] = "http://www.example.com/#{thing}"
        item_attributes[:is_version_of] = ["The CDROM titled '#{thing.pluralize.capitalize}!'",
                                      'The original laserdisc series from Orange-on-a-Blue-Background studios']
        item_attributes[:source] = "Chapter 5 of '#{thing.pluralize.capitalize} and what they drink'"
      end

      item = Item.new(item_attributes).tap do |uo|
        if i == 8
          uo.add_to_path(community.id, item_collection.id)
          uo.add_to_path(community.id, thesis_collection.id)
          uo.save!
        else
          uo.add_to_path(community.id, item_collection.id)
          uo.save!
        end
      end

      if i == 8
        # Attach two files to the mondo-item
        File.open(Rails.root + 'app/javascript/images/theses.jpg', 'r') do |file1|
          File.open(Rails.root + 'test/fixtures/files/image-sample.jpeg', 'r') do |file2|
            # Bit of a hack to fake a long file name ...
            def file2.original_filename
              'wefksdkhvkasdkfjhwekkjahsdkjkajvbkejfkwejfjkdvkhdkfhw&ükefkhoiekldkfhkdfjhiwuegfugksjdcjbsjkdbw.jpeg'
            end
            item.add_and_ingest_files([file1, file2])
          end
        end
      end
      item.set_thumbnail(item.files.first) if item.files.first.present?

      field = Faker::Job.field
      level = ["Master's", 'Doctorate'][i % 2]
      thesis_attributes = base_attributes.merge({
        owner_id: admin.id,
        title: "Thesis about the effects of #{Faker::Beer.name} on #{thing.pluralize}",
        graduation_date: "Fall #{rand(20_000).days.ago.year}",
        dissertant: creators[seed],
        abstract: description,
        language: languages.first,
        specialization: field,
        departments: ["Deparment of #{field}"],
        supervisors: ["#{contributors[seed]} (#{field})"],
        committee_members: ["#{contributors[seed2]} (#{field})"],
        rights: 'Share my stuff with everybody',
        thesis_level: level,
        degree: "#{level} of #{field}",
        institution: institutions[(i / 10) % 2]
      })

      # Every once in a while, create a mondo-thesis with full, rich metadata to help view-related work
      if i == 8
        thesis_attributes[:title] = thesis_attributes[:title].gsub(/^Thesis/, 'An über-thesis')
        thesis_attributes[:subject] += ['Mondo']
        thesis_attributes[:alternative_title] = "A full, holistic, #{thing}-tastic approach"
        thesis_attributes[:is_version_of] = ["The CDROM titled '#{thing.pluralize.capitalize}!'",
                                      'The original laserdisc series from Orange-on-a-Blue-Background studios']
        department2 = 'Department of Everything'
        thesis_attributes[:departments] += [department2]
        thesis_attributes[:supervisors] += ["#{contributors[(seed + 3 * seed2) % 10]} (#{department2})"]
        thesis_attributes[:committee_members] += ["#{contributors[(seed + 7 * seed2) % 10]} (#{department2})"]
      end

      thesis = Thesis.new(thesis_attributes).tap do |uo|
        if i == 8
          uo.add_to_path(community.id, item_collection.id)
          uo.add_to_path(community.id, thesis_collection.id)
          uo.save!
        else
          uo.add_to_path(community.id, thesis_collection.id)
          uo.save!
        end
      end
      if i == 8
        # To test PCDM/list_source ordering, attach three files to the mondo-thesis!
        File.open(Rails.root + 'app/javascript/images/theses.jpg', 'r') do |file1|
          File.open(Rails.root + 'test/fixtures/files/image-sample.jpeg', 'r') do |file2|
            File.open(Rails.root + 'app/javascript/images/era-logo.png', 'r') do |file3|
              thesis.add_and_ingest_files([file1, file2, file3])
            end
          end
        end
      end
      thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?
    end

    # Add a private item
    Item.new(
      owner_id: admin.id,
      creators: [creators[rand(10)]],
      visibility: JupiterCore::VISIBILITY_PRIVATE,
      created: rand(20_000).days.ago.to_s,
      title: "Private #{thing.pluralize}, public lives: a survey of social media trends",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].chapter,
      subject: [thing.capitalize, 'Privacy'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.save!
    end

    # Add a CCID protected item
    Item.new(
      owner_id: admin.id,
      creators: [creators[rand(10)]],
      visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
      created: rand(20_000).days.ago.to_s,
      title: "Everything You Need To Know About: University of Alberta and #{thing.pluralize}!",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].report,
      subject: [thing.capitalize, 'CCID'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.save!
    end

    # Add a currently embargoed item
    Item.new(
      owner_id: admin.id,
      creators: [creators[rand(10)]],
      visibility: Item::VISIBILITY_EMBARGO,
      created: rand(20_000).days.ago.to_s,
      title: "Embargo and #{Faker::Address.country}: were the #{thing.pluralize} left behind?",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].conference_workshop_presentation,
      subject: [thing.capitalize, 'Embargoes'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.embargo_end_date = 20.years.from_now.to_date
      uo.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
      uo.save!
    end

    # Add a formerly embargoed item
    Item.new(
      owner_id: admin.id,
      creators: [creators[rand(10)]],
      visibility: Item::VISIBILITY_EMBARGO,
      created: rand(20_000).days.ago.to_s,
      title: "Former embargo of #{Faker::Address.country}: the day the #{thing.pluralize} were free",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].dataset,
      subject: [thing.capitalize, 'Freedom'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.embargo_end_date = 2.days.ago.to_date
      uo.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
      uo.save!
    end

    # Add an item owned by non-admin
    Item.new(
      owner_id: non_admin.id,
      creators: [creators[rand(10)]],
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      created: rand(20_000).days.ago.to_s,
      title: "Impact of non-admin users on #{thing.pluralize}",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].learning_object,
      subject: [thing.capitalize, 'Equality'],
      # Add a temporal subject
      temporal_subjects: ['The 1950s'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.save!
    end

    # Want one multi-collection item per community
    Item.new(
      owner_id: admin.id,
      creators: [creators[rand(10)]],
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      created: rand(20_000).days.ago.to_s,
      title: "Multi-collection random images of #{thing.pluralize}",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop,
      # No linguistic content
      languages: [CONTROLLED_VOCABULARIES[:language].no_linguistic_content],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].image,
      subject: [thing.capitalize, 'Randomness', 'Pictures'],
      # Add a spacial subject
      spatial_subjects: ['Onoway'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).tap do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.add_to_path(community.id, thesis_collection.id)
      uo.save!
    end
  end

  # Pad with empty communities for pagination (starts with Z for sort order)
  EXTRA_THINGS.each do |thing|
    Community.create!(
      owner_id: admin.id,
      title: "Zoo#{thing}ology Institute of North-Eastern Upper Alberta (and Saskatchewan)",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
    )
  end

  # One community with a lot of empty restricted collections
  community = Community.create!(
    owner_id: admin.id,
    title: "The Everything Department",
    description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
  )

  EXTRA_THINGS.each do |thing|
    Collection.create!(
      owner_id: admin.id,
      title: "Articles about the relationship between #{thing.pluralize} and non-#{thing.pluralize}",
      community_id: community.id,
      restricted: true,
      description: "A restricted collection"
    )
  end

  # Radioactive entities
  # TODO: Add our own radioactive community and collection

  community_with_collection = Community.joins(:collections).first
  radioactive_example_file_paths = ['test/fixtures/files/image-sample.jpeg', 'test/fixtures/files/image-sample2.jpeg']

  base_radioactive_item_values = {
    # Set model id on each new Item so we can find it easily when testing
    owner_id: admin.id,
    doi: 'doi:10.7939/xxxxxxxxx',
    visibility: JupiterCore::VISIBILITY_PUBLIC,
    creators: ['dc:creator1$ Doe, Jane', 'dc:creator2$ Doe, John'],
    contributors: ['dc:contributor1$ Perez, Juan', 'dc:contributor2$ Perez, Maria'],
    subject: ['dc:subject1$ Some subject heading', 'dc:subject2$ Some subject heading'],
    created: '2000-01-01',
    sort_year: '2000',
    description: 'dcterms:description1$ Arabic ناتيومرلبسفأعدقحكهجشطصزخضغذثئةظؤىءآإ Greek αβγδεζηθικλμνξοπρςστυφχψω ' \
                 'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ Cyrillic абвгдеёжзийклмнопрстуфхцчшщъыьэюя ' \
                 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ Lao ກ-ໝ Thai ก-๎ Burmese က-ၙ Khmer ក-៹ Korean 가-힣 Bengali অ-ৱ // ' \
                 'Spanish áéíóúüñ French àâçèéêëîïôùûü Portuguese àáâãçéêíóôõú Hindi ऄ-ॿ Pujabi ਅ-ੴ Mandarin ' \
                 '海萵苣白菜冬瓜韭菜竹筍生菜大頭菜豆薯銀甜菜莧菜豌豆蒲公英蔥豌豆苗亞羅婆羅門參西葫蘆。小豆辣根土豆 Japanese ' \
                 'アオサメロンキャベツニラ竹シュートレタスルタバガのクズイモ銀ビートアマランスエンドウタンポポねぎ',
    is_version_of: [
      'dcterms:isVersionOf1$ Sydorenko, Dmytro & Rankin, Robert. (2013). Simulation of O+ upflows created by ' \
      'electron precipitation and Alfvén waves in the ionosphere. Journal of Geophysical Research: Space Physics, ' \
      '118(9), 5562-5578. http://doi.org/10.1002/jgra.50531',
      'dcterms:isVersionOf2$ Another version'
    ],
    languages: [CONTROLLED_VOCABULARIES[:language].no_linguistic_content, CONTROLLED_VOCABULARIES[:language].french],
    related_link: 'dcterms:relation1$ http://doi.org/10.1007/xxxxxx-xxx-xxxx-x',
    source: 'dcterms:source1$ Some source',
    spatial_subjects: ['dcterms:spatial1$ Canada', 'dcterms:spatial2$ Nicaragua'],
    temporal_subjects: ['dcterms:temporal1$ Holocene', 'dcterms:temporal2$ Holocene'],
    title: 'dcterms:title1$ Some Title for Item',
    alternative_title: 'dcterms:alternative1$ Some Alternative Title',
    item_type: CONTROLLED_VOCABULARIES[:item_type].image,
    depositor: 'eraadmi@ualberta.ca',
    license: CONTROLLED_VOCABULARIES[:license].attribution_sharealike_4_0_international,
    fedora3_uuid: 'uuid:97b1a8e2-a4b9-4941-b6ed-c4730f0a2a61',
    fedora3_handle: 'http://hdl.handle.net/10402/era.33419',
    hydra_noid: 'cgq67jr26k',
    ingest_batch: '9019s326c',
    date_ingested: '2000-01-01T00:00:00.007Z',
    record_created_at: '2000-01-01T00:00:00.007Z',
    member_of_paths: ["#{community_with_collection.id}/#{community_with_collection.collections[0].id}"]
  }

  Item.new(
    base_radioactive_item_values.merge(id: 'e2ec88e3-3266-4e95-8575-8b04fac2a679')
  ).tap do |item|
    # Attach files

    radioactive_example_file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item.save!
  end

  # Add Item with rigts value and no license
  Item.new(
    base_radioactive_item_values.merge(
      # Values for both license and rights cannot be set at the same time
      id: 'c795337f-075f-429a-bb18-16b56d9b750f',
      license: '',
      rights: '© The Author(s) 2015. Published by Oxford University Press on behalf of the Society for Molecular ' \
      'Biology and Evolution.'
    )
  ).tap do |item|
    # Attach files

    radioactive_example_file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item.save!
  end

  # Add Item with that is currently embargoed
  Item.new(
    base_radioactive_item_values.merge(
      id: '3bb26070-0d25-4f0e-b44f-e9879da333ec',
      # In order to set embargo values the visibility value needs to be set to
      visibility: Item::VISIBILITY_EMBARGO,
      embargo_history: ['acl:embargoHistory1$ Item currently embargoed'],
      embargo_end_date: '2080-01-01T00:00:00.000Z',
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    )
  ).tap do |item|
    # Attach files

    radioactive_example_file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item.save!
  end

  # Add Item that was previously embargoed
  Item.new(
    base_radioactive_item_values.merge(
      id: '2107bfb6-2670-4ffc-94a1-aeb4f8c1fd81',
      # In order to set embargo values the visibility value needs to be set to
      visibility: Item::VISIBILITY_EMBARGO,
      embargo_end_date: '2000-01-01T00:00:00.000Z',
      embargo_history: [
        'acl:embargoHistory1$ An expired embargo was deactivated on 2000-01-01T00:00:00.000Z.  Its release date was ' \
        '2000-01-01T00:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo ' \
        'was open',
        'acl:embargoHistory2$ An expired embargo was deactivated on 2000-01-01T00:00:00.000Z.  Its release date was ' \
        '2000-01-01T00:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo '\
        'was open'
      ],
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    )
  ).tap do |item|
    # Attach files

    radioactive_example_file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item.save!
  end

  # Add Item with article type and publication status

  Item.new(
    base_radioactive_item_values.merge(
      id: '93126aae-4b9d-4db2-98f1-4e04b40778cf',
      # The value for publication_status published only appears for article item type
      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published]
    )
  ).tap do |item|
    # Attach files

    radioactive_example_file_paths.each do |file_path|
      File.open(Rails.root + file_path, 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    item.set_thumbnail(item.files.first) if item.files.first.present?

    item.save!
  end

end

base_radioactive_thesis_values = {
  visibility: JupiterCore::VISIBILITY_PUBLIC,
  owner_id: admin.id,
  hydra_noid: 'c6108vb30p',
  record_created_at: '2018-03-13T16:52:49.818Z',
  date_ingested: '2018-03-13T16:52:49.818Z',
  title: 'dcterms:title1$ Some Thesis Title',
  fedora3_uuid: 'uuid:a4701510-ef9b-45cf-a7d0-2d2f16e00787',
  depositor: 'lisboa@ualberta.ca',
  alternative_title: 'dcterms:alternative1$ Some Alternative Title',
  doi: 'doi:10.7939/R3V980074',
  fedora3_handle: 'http://hdl.handle.net/10402/era.40349',
  ingest_batch: '6395w734s',
  rights: 'dc:rights1$ Some license terms',
  sort_year: '2015',
  is_version_of: [
    'dcterms:isVersionOf1$ Lartey, S., Cummings, G. G., & Profetto-McGrath, J. (2013). Interventions that promote ' \
    'retention of experienced registered nurses in health care settings: A systematic review. Journal of Nursing ' \
    'Management. doi: 10.1111/jonm.12105'
  ],
  member_of_paths: ["#{community_with_collection.id}/#{community_with_collection.collections[0].id}"],
  subject: [
    'dc:subject1$ Some subject heading',
    'dc:subject2$ Some subject heading',
    'dc:subject3$ Some subject heading'
  ],
  abstract: 'dcterms:abstract1$ Arabic ناتيومرلبسفأعدقحكهجشطصزخضغذثئةظؤىءآإ Greek αβγδεζηθικλμνξοπρςστυφχψω ' \
  'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ Cyrillic абвгдеёжзийклмнопрстуфхцчшщъыьэюя АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ Lao ກ-ໝ ' \
  'Thai ก-๎ Burmese က-ၙ Khmer ក-៹ Korean 가-힣 Bengali অ-ৱ // Spanish áéíóúüñ French àâçèéêëîïôùûü Portuguese ' \
  'àáâãçéêíóôõú Hindi ऄ-ॿ Pujabi ਅ-ੴ Mandarin 海萵苣白菜冬瓜韭菜竹筍生菜大頭菜豆薯銀甜菜莧菜豌豆蒲公英蔥豌豆苗亞羅婆羅門參西葫蘆 ' \
  '小豆辣根土豆 Japanese アオサメロンキャベツニラ竹シュートレタスルタバガのクズイモ銀ビートアマランスエンドウタンポポねぎ',
  language: CONTROLLED_VOCABULARIES[:language].english,
  date_accepted: '2014-12-23T15:33:25Z',
  date_submitted: '2014-12-23T14:50:01Z',
  degree: 'bibo:degree1$ Doctor of Philosophy',
  institution: 'http://id.loc.gov/authorities/names/n79058482',
  dissertant: 'ual:dissertant$1 Lisboa, Luiz',
  graduation_date: '2015-06',
  thesis_level: 'ual:thesisLevel1$ Doctoral',
  proquest: 'NN88234',
  unicorn: '2133190',
  specialization: 'ual:specialization1$ Experimental Medicine',
  departments: [
    'ual:department1$ Department of Medicine',
    'ual:department2$ Department of Something',
    'ual:department3$ Another Department'
  ],
  supervisors: [
    'ual:supervisor1$ Humar, Atul (Medicine)',
    'ual:supervisor2$ Kumar, Deepali (Medicine)',
    'ual:supervisor3$ Tyrrell, D. Lorne (Medicine)'
  ],
  committee_members: [
    'ual:commiteeMember1$ Hemmings, Denise (Obstetrics & Gynecology)',
    'ual:commiteeMember2$ Humar, Atul (Medicine)',
    'ual:commiteeMember3$ McMurtry, M. Sean (Medicine)'
  ],
  aasm_state: 'available'
}

# Add base radioactive Thesis
Thesis.new(
  base_radioactive_thesis_values.merge(id: '8e18f37c-dc60-41bb-9459-990586176730')
).tap do |thesis|
  # Attach files

  radioactive_example_file_paths.each do |file_path|
    File.open(Rails.root + file_path, 'r') do |file|
      thesis.add_and_ingest_files([file])
    end
  end

  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?

  thesis.save!
end

# Add Thesis that is currently embargoed
Thesis.new(
  base_radioactive_thesis_values.merge(
    id: 'b3cc2224-9303-47be-8b54-e6556a486be8',
    visibility: Thesis::VISIBILITY_EMBARGO,
    embargo_history: ['acl:embargoHistory1$ Thesis currently embargoed'],
    embargo_end_date: '2080-01-01T00:00:00.000Z',
    visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
  )
).tap do |thesis|
  # Attach files

  radioactive_example_file_paths.each do |file_path|
    File.open(Rails.root + file_path, 'r') do |file|
      thesis.add_and_ingest_files([file])
    end
  end

  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?

  thesis.save!
end

# Add Thesis that was previously embargoed
Thesis.new(
  base_radioactive_thesis_values.merge(
    id: '9d7c12f0-b396-4511-ba0e-c012ec028e8a',
    # In order to set embargo values the visibility value needs to be set to
    visibility: Thesis::VISIBILITY_EMBARGO,
    embargo_end_date: '2000-01-01T00:00:00.000Z',
    embargo_history: [
      'acl:embargoHistory1$ An expired embargo was deactivated on 2016-06-15T18:00:15.651Z.  Its release date was ' \
      '2016-06-15T06:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo ' \
      'was open'
    ],
    visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
  )
).tap do |thesis|
  # Attach files

  radioactive_example_file_paths.each do |file_path|
    File.open(Rails.root + file_path, 'r') do |file|
      thesis.add_and_ingest_files([file])
    end
  end

  thesis.set_thumbnail(thesis.files.first) if thesis.files.first.present?

  thesis.save!
end

# Types
[:book, :book_chapter, :conference_workshop_poster,
 :conference_workshop_presentation, :dataset,
 :image, :journal_article_draft, :journal_article_published,
 :learning_object, :report, :research_material, :review].each do |type_name|
  Type.create(name: type_name)
end

# Languages
[:english, :french, :spanish, :chinese, :german,
 :italian, :russian, :ukrainian, :japanese,
 :no_linguistic_content, :other].each do |language_name|
  Language.create(name: language_name)
end

# Institutions
[:uofa, :st_stephens].each do |institution_name|
  Institution.create(name: institution_name)
end

puts 'Database seeded successfully!'
