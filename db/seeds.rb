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
        creator = [creators[seed]]
        # Add the occasional double-author work
        creator << creators[(seed + 5) % 10] if i % 7 == 3
        # Add one with a ton of authors
        creator += 6.times.map { |j| creators[(seed + 3 * j) % 10] } if i == 18
        # Add an occasional verbose description
        description = if i % 10 == 5
                        Faker::Lorem.sentence(100, false, 0).chop
                      else
                        Faker::Lorem.sentence(20, false, 0).chop
                      end
        # 20% French
        language = if seed > 2
                     'English'
                   else
                     'French'
                   end
        Item.new_locked_ldp_object(
          owner: admin.id,
          creator: creator.uniq,
          contributor: [contributors[rand(10)]],
          created: (Time.now - rand(20_000).days).to_s,
          visibility: JupiterCore::VISIBILITY_PUBLIC,
          title: "The effects of #{Faker::Beer.name} on #{thing.pluralize}",
          description: description,
          language: language
        ).unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(community.id, collection.id)
          uo.save!
        end
      end

      # Add an private item
      Item.new_locked_ldp_object(
        owner: admin.id,
        visibility: JupiterCore::VISIBILITY_PRIVATE,
        title: "Private #{thing.pluralize}, public lives: a survey of social media trends",
        description: Faker::Lorem.sentence(20, false, 0).chop
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end

      # Add a currently embargoed item
      Item.new_locked_ldp_object(
        owner: admin.id,
        visibility: Item::VISIBILITY_EMBARGO,
        title: "Embargo and #{Faker::Address.country}: were the #{thing.pluralize} left behind?",
        description: Faker::Lorem.sentence(20, false, 0).chop
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.embargo_end_date = (Time.now + 20.years).to_date
        uo.save!
      end

      # Add a formerly embargoed item
      Item.new_locked_ldp_object(
        owner: admin.id,
        visibility: Item::VISIBILITY_EMBARGO,
        title: "Former embargo of #{Faker::Address.country}: the day the #{thing.pluralize} were free",
        description: Faker::Lorem.sentence(20, false, 0).chop
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.embargo_end_date = (Time.now - 2.days).to_date
        uo.save!
      end

      # Add an item owned by non-admin
      Item.new_locked_ldp_object(
        owner: non_admin.id,
        visibility: JupiterCore::VISIBILITY_PUBLIC,
        title: "Impact of non-admin users on #{thing.pluralize}",
        description: Faker::Lorem.sentence(20, false, 0).chop
      ).unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end

    end

    # Want one multi-collection item per community
    Item.new_locked_ldp_object(
      owner: admin.id,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      title: "Multi-collection random images of #{thing.pluralize}",
      description: Faker::Lorem.sentence(20, false, 0).chop
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
