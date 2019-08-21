# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development? || Rails.env.uat?
  require 'active_fedora/cleaner'
  require "open-uri"
  require 'faker'

  # For the main community/collections
  THINGS = ['cat', 'dog', 'unicorn', 'hamburger', 'librarian'].freeze
  # For padding community/collection lists for pagination (need at least 26, a couple uppercase to confirm sort)
  EXTRA_THINGS = ['Library', 'DONAIR', 'magpie', 'toque', 'sombrero', 'yeti', 'mimosa', 'ukulele', 'tourtière',
                   'falafel', 'calculator', 'papusa'].freeze

  puts 'Starting seeding of dev database...'

  # start fresh
  [Announcement, ActiveStorage::Blob, ActiveStorage::Attachment, JupiterCore::AttachmentShim,
   Identity, User, Type, Language, Institution].each(&:destroy_all)

  ActiveFedora::Cleaner.clean!

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
    community = Community.new_locked_ldp_object(
      owner: admin.id,
      title: title,
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)

    # Attach logos, if possible
    filename = File.expand_path(Rails.root + "tmp/#{thing}.png")
    unless File.exist?(filename)
      unless ENV['SKIP_DOWNLOAD_COMMUNITY_LOGOS'].present?
        set = (thing == 'cat') ? 'set4' : 'set1'
        url = Faker::Avatar.image(thing, "100x100", "png", set)
        File.open(filename, 'wb') do |fo|
          fo.write open(url).read
        end
      end
    end
    if File.exist?(filename)
      community.logo.attach(io: File.open(filename), filename: "#{thing}.png", content_type: "image/png")
    end

    item_collection = Collection.new_locked_ldp_object(
      owner: admin.id,
      title: "The annals of '#{thing.capitalize} International'",
      community_id: community.id,
      description: Faker::Lorem.sentence(word_count: 40, supplemental: false, random_words_to_add: 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)

    thesis_collection = Collection.new_locked_ldp_object(
      owner: admin.id,
      title: "Theses about #{thing.pluralize}",
      community_id: community.id,
      description: Faker::Lorem.sentence(word_count: 40, supplemental: false, random_words_to_add: 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)

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

      item = Item.new(item_attributes).unlock_and_fetch_ldp_object do |uo|
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
        File.open(Rails.root + 'app/assets/images/theses.jpg', 'r') do |file1|
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
        owner: admin.id,
        title: "Thesis about the effects of #{Faker::Beer.name} on #{thing.pluralize}",
        graduation_date: "#{rand(20_000).days.ago.year}#{['-06','-11',''][i % 3]}",
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

      thesis = Thesis.new_locked_ldp_object(thesis_attributes).unlock_and_fetch_ldp_object do |uo|
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
        File.open(Rails.root + 'app/assets/images/theses.jpg', 'r') do |file1|
          File.open(Rails.root + 'test/fixtures/files/image-sample.jpeg', 'r') do |file2|
            File.open(Rails.root + 'app/assets/images/era-logo.png', 'r') do |file3|
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
    ).unlock_and_fetch_ldp_object do |uo|
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
    ).unlock_and_fetch_ldp_object do |uo|
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
    ).unlock_and_fetch_ldp_object do |uo|
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
    ).unlock_and_fetch_ldp_object do |uo|
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
    ).unlock_and_fetch_ldp_object do |uo|
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
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(community.id, item_collection.id)
      uo.add_to_path(community.id, thesis_collection.id)
      uo.save!
    end
  end

  # Pad with empty communities for pagination (starts with Z for sort order)
  EXTRA_THINGS.each do |thing|
    Community.new_locked_ldp_object(
      owner: admin.id,
      title: "Zoo#{thing}ology Institute of North-Eastern Upper Alberta (and Saskatchewan)",
      description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)
  end

  # One community with a lot of empty restricted collections
  community = Community.new_locked_ldp_object(
    owner: admin.id,
    title: "The Everything Department",
    description: Faker::Lorem.sentence(word_count: 20, supplemental: false, random_words_to_add: 0).chop
  ).unlock_and_fetch_ldp_object(&:save!)

  EXTRA_THINGS.each do |thing|
    collection = Collection.new_locked_ldp_object(
      owner: admin.id,
      title: "Articles about the relationship between #{thing.pluralize} and non-#{thing.pluralize}",
      community_id: community.id,
      restricted: true,
      description: "A restricted collection"
    ).unlock_and_fetch_ldp_object(&:save!)
  end

end

# Types
[:book, :book_chapter, :conference_workshop_poster,
 :conference_workshop_presentation, :dataset,
 :image, :journal_article_draft, :journal_article_published,
 :learning_object, :report, :research_material, :review].each do |type_name|
  Type.where(name: type_name).first_or_create
end

# Languages
[:english, :french, :spanish, :chinese, :german,
 :italian, :russian, :ukrainian, :japanese,
 :no_linguistic_content, :other].each do |language_name|
  Language.where(name: language_name).first_or_create
end

# Institutions
[:uofa, :st_stephens].each do |institution_name|
  Institution.where(name: institution_name).first_or_create
end


puts 'Database seeded successfully!'
