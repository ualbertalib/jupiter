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
  THINGS = [ 'cat', 'dog', 'unicorn', 'hamburger', 'librarian'].freeze
  # For padding community/collection lists for pagination (need at least 26, a couple uppercase to confirm sort)
  EXTRA_THINGS = [ 'Library', 'DONAIR', 'magpie', 'toque', 'sombrero', 'yeti', 'mimosa', 'ukulele', 'tourtière',
                   'falafel', 'calculator', 'papusa'].freeze

  puts 'Starting seeding of dev database...'

  # start fresh
  [Announcement, ActiveStorage::Blob, ActiveStorage::Attachment, Identity, User].each(&:destroy_all)
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
    name = Faker::GameOfThrones.unique.character
    User.create(name: name, email: "#{name.gsub(/ +/, '.').downcase}@example.edu", admin: false)
  end

  # Lets pick 10 prolific creators, 10 contributors
  creators = 10.times.map { "#{Faker::Cat.unique.name} #{Faker::Cat.unique.breed.gsub(/[ ,]+/, '-')}" }
  contributors = 10.times.map { Faker::FunnyName.unique.name_with_initial }

  THINGS.each_with_index do |thing, idx|
    if idx % 2 == 0
      title = "The department of #{thing.capitalize}"
    else
      title = "Special reports about #{thing.pluralize}"
    end
    community = Community.new_locked_ldp_object(
      owner: admin.id,
      title: title,
      description: Faker::Lorem.sentence(20, false, 0).chop
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

    collection_first = collection_last = nil
    [ "Theses about #{thing.pluralize}",
      "The annals of '#{thing.capitalize} International'"].each do |title|
      collection = Collection.new_locked_ldp_object(
        owner: admin.id,
        title: title,
        community_id: community.id,
        description: Faker::Lorem.sentence(40, false, 0).chop
      ).unlock_and_fetch_ldp_object(&:save!)

      collection_first ||= collection
      collection_last = collection

      20.times do |i|
        seed = rand(10)
        seed2 = rand(10)
        # Add an occasional verbose description
        description = if i % 10 == 5
                        Faker::Lorem.sentence(100, false, 0).chop
                      else
                        Faker::Lorem.sentence(20, false, 0).chop
                      end
        # Probabilistically about 70% English, 20% French, 10% Ukrainian
        languages = if seed % 10 > 2
                      [CONTROLLED_VOCABULARIES[:language].eng]
                    elsif seed % 10 > 0
                      [CONTROLLED_VOCABULARIES[:language].fre]
                    else
                      [CONTROLLED_VOCABULARIES[:language].ukr]
                    end
        licence_right = {}
        attributes = {
          owner: admin.id,
          creators: [creators[seed]],
          contributors: [contributors[seed2]],
          created: (Time.now - rand(20_000).days).to_s,
          visibility: JupiterCore::VISIBILITY_PUBLIC,
          title: "The effects of #{Faker::Beer.name} on #{thing.pluralize}",
          description: description,
          languages: languages,
          subject: [thing.capitalize],
          doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
        }
        # Add the occasional double-author work
        attributes[:creators] << creators[(seed + 5) % 10] if i % 7 == 3
        if seed % 10 < 6
          attributes[:license] = CONTROLLED_VOCABULARIES[:license].attribution_4_0_international
        elsif seed % 10 < 7
          attributes[:license] = CONTROLLED_VOCABULARIES[:license].public_domain_mark_1_0
        elsif seed % 10 < 8
          attributes[:license] = CONTROLLED_VOCABULARIES[:old_license].attribution_3_0_international
        else
          attributes[:rights] = 'Share my stuff with everybody'
        end
        if idx % 3 == 0
          attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].article
          attributes[:publication_status] = [CONTROLLED_VOCABULARIES[:publication_status].published]
        elsif idx % 3 == 1
          attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].article
          attributes[:publication_status] = [CONTROLLED_VOCABULARIES[:publication_status].draft,
                                             CONTROLLED_VOCABULARIES[:publication_status].submitted]
        else
          attributes[:item_type] = CONTROLLED_VOCABULARIES[:item_type].report
        end

        # Every once in a while, create a mondo-item with full, rich metadata to help view-related work
        if i == 8
          attributes[:title] = attributes[:title].gsub(/^The/, 'The complete')
          # Throw in a second language occasionally
          attributes[:languages] << CONTROLLED_VOCABULARIES[:language].other
          # Why 3 and 7 below? Neither number shares a divisor with 10, ensuring a unique set
          attributes[:creators] += 4.times.map { |j| creators[(seed + 3 * j) % 10] }
          attributes[:contributors] += 3.times.map { |j| contributors[(seed2 + 7 * j) % 10] }
          attributes[:subject] += ['Mondo']
          attributes[:spatial_subjects] = ['Vegreville']
          attributes[:temporal_subjects] = ['1980s']
          attributes[:alternative_title] = "A full, holistic, #{thing}-tastic approach"
          attributes[:related_link] = "http://www.example.com/#{thing}"
          attributes[:is_version_of] = ["The CDROM titled '#{thing.pluralize.capitalize}!'",
                                        'The original laserdisc series from Orange-on-a-Blue-Background studios']
          attributes[:derived_from] = "Chapter 5 of '#{thing.pluralize.capitalize} and what they drink'"
        end

        Item.new_locked_ldp_object(attributes).unlock_and_fetch_ldp_object do |uo|
          if i == 8
            uo.add_to_path(community.id, collection_first.id)
            uo.add_to_path(community.id, collection_last.id)
            uo.save!
            # Attach a file to the mondo-item
            file = File.open(Rails.root + 'app/assets/images/mc_360.png', 'r')
            uo.add_files([file])
            file.close
          else
            uo.add_to_path(community.id, collection.id)
            uo.save!
          end
        end
      end

      # Add an private item
      Item.new_locked_ldp_object(
        owner: admin.id,
        creators: [creators[rand(10)]],
        visibility: JupiterCore::VISIBILITY_PRIVATE,
        created: (Time.now - rand(20_000).days).to_s,
        title: "Private #{thing.pluralize}, public lives: a survey of social media trends",
        description: Faker::Lorem.sentence(20, false, 0).chop,
        languages: [CONTROLLED_VOCABULARIES[:language].eng],
        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
        item_type: CONTROLLED_VOCABULARIES[:item_type].chapter,
        subject: [thing.capitalize, 'Privacy'],
        doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end

      # Add a currently embargoed item
      Item.new_locked_ldp_object(
        owner: admin.id,
        creators: [creators[rand(10)]],
        visibility: Item::VISIBILITY_EMBARGO,
        created: (Time.now - rand(20_000).days).to_s,
        title: "Embargo and #{Faker::Address.country}: were the #{thing.pluralize} left behind?",
        description: Faker::Lorem.sentence(20, false, 0).chop,
        languages: [CONTROLLED_VOCABULARIES[:language].eng],
        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
        item_type: CONTROLLED_VOCABULARIES[:item_type].conference_paper,
        subject: [thing.capitalize, 'Embargoes'],
        doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.embargo_end_date = (Time.now + 20.years).to_date
        uo.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
        uo.save!
      end

      # Add a formerly embargoed item
      Item.new_locked_ldp_object(
        owner: admin.id,
        creators: [creators[rand(10)]],
        created: (Time.now - rand(20_000).days).to_s,
        visibility: Item::VISIBILITY_EMBARGO,
        title: "Former embargo of #{Faker::Address.country}: the day the #{thing.pluralize} were free",
        description: Faker::Lorem.sentence(20, false, 0).chop,
        languages: [CONTROLLED_VOCABULARIES[:language].eng],
        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
        item_type: CONTROLLED_VOCABULARIES[:item_type].dataset,
        subject: [thing.capitalize, 'Freedom'],
        doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.embargo_end_date = (Time.now - 2.days).to_date
        uo.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
        uo.save!
      end

      # Add an item owned by non-admin
      Item.new_locked_ldp_object(
        owner: non_admin.id,
        creators: [creators[rand(10)]],
        visibility: JupiterCore::VISIBILITY_PUBLIC,
        created: (Time.now - rand(20_000).days).to_s,
        title: "Impact of non-admin users on #{thing.pluralize}",
        description: Faker::Lorem.sentence(20, false, 0).chop,
        languages: [CONTROLLED_VOCABULARIES[:language].eng],
        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
        item_type: CONTROLLED_VOCABULARIES[:item_type].learning_object,
        subject: [thing.capitalize, 'Equality'],
        # Add a temporal subject
        temporal_subjects: ['The 1950s'],
        doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end

    end

    # Want one multi-collection item per community
    Item.new_locked_ldp_object(
      owner: admin.id,
      creators: [creators[rand(10)]],
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      created: (Time.now - rand(20_000).days).to_s,
      title: "Multi-collection random images of #{thing.pluralize}",
      description: Faker::Lorem.sentence(20, false, 0).chop,
      # No linguistic content
      languages: [CONTROLLED_VOCABULARIES[:language].zxx],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      item_type: CONTROLLED_VOCABULARIES[:item_type].image,
      subject: [thing.capitalize, 'Randomness', 'Pictures'],
      # Add a spacial subject
      spatial_subjects: ['Onoway'],
      doi: "doi:bogus-#{Time.current.utc.iso8601(3)}"
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(community.id, collection_first.id)
      uo.add_to_path(community.id, collection_last.id)
      uo.save!
    end
  end

  # Pad with empty communities for pagination (starts with Z for sort order)
  EXTRA_THINGS.each do |thing|
    Community.new_locked_ldp_object(
      owner: admin.id,
      title: "Zoo#{thing}ology Institute of North-Eastern Upper Alberta (and Saskatchewan)",
      description: Faker::Lorem.sentence(20, false, 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)
  end

  # One community with a lot of empty collections
  community = Community.new_locked_ldp_object(
    owner: admin.id,
    title: "The Everything Department",
    description: Faker::Lorem.sentence(20, false, 0).chop
  ).unlock_and_fetch_ldp_object(&:save!)

  EXTRA_THINGS.each do |thing|
    collection = Collection.new_locked_ldp_object(
      owner: admin.id,
      title: "Articles about the relationship between #{thing.pluralize} and non-#{thing.pluralize}",
      community_id: community.id,
      description: Faker::Lorem.sentence(40, false, 0).chop
    ).unlock_and_fetch_ldp_object(&:save!)
  end
  puts 'Database seeded successfully!'
end
