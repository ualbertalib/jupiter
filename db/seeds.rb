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
  (0..100).each do
    name = Faker::GameOfThrones.unique.character
    User.create(name: name, email: "#{name.gsub(/ +/, '.').downcase}@example.edu", admin: false)
  end

  # Lets pick 10 prolific creators, 10 contributors
  creators = (0..9).map { "#{Faker::Cat.unique.name} #{Faker::Cat.unique.breed}" }
  contributors = (0..9).map { Faker::FunnyName.unique.name_with_initial }

  [ "cat", "dog", "unicorn", "hamburger", "librarian"].each_with_index do |thing, idx|
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

      (0..20).each do
        Item.new_locked_ldp_object(
          owner: admin.id,
          creator: creators[rand(10)],
          contributor: contributors[rand(10)],
          visibility: JupiterCore::VISIBILITY_PUBLIC,
          title: "The effects of #{Faker::Beer.name} on #{thing.pluralize}",
          description: Faker::Lorem.sentence(20, false, 0).chop,
          language: rand(10) > 2 ? 'English' : 'French'
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

  puts 'Database seeded successfully!'
end
