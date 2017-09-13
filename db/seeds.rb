# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Rails.env.development?
  require 'active_fedora/cleaner'
  require "open-uri"

  puts 'Starting seeding of dev database...'

  # start fresh
  [ SiteNotification, ActiveStorage::Blob, ActiveStorage::Attachment, Identity, User ].each(&:destroy_all)
  ActiveFedora::Cleaner.clean!

  # Seed an admin user
  admin = User.create(name: 'Admin', email: 'admin@ualberta.ca', admin: true)
  admin.identities.create(provider: 'developer', uid: 'admin@ualberta.ca')

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
      if ENV['DOWNLOAD_COMMUNITY_LOGOS'].present?
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
        community_id: community.id
      ).unlock_and_fetch_ldp_object(&:save!)

      collection_first ||= collection
      collection_last = collection

      (0..20).each do
        Item.new_locked_ldp_object(
          owner: admin.id,
          visibility: JupiterCore::VISIBILITY_PUBLIC,
          title: "The effects of #{Faker::Beer.name} on #{thing.pluralize}",
          description: Faker::Lorem.sentence(20, false, 0).chop,
          # will not be required in future, probably will have a created_at field
          date_created: Time.zone.now.to_s
        ).unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(community.id, collection.id)
          uo.save!
        end
      end
    end

    # Want one multi-collection item per community
    Item.new_locked_ldp_object(
      owner: admin.id,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      title: "Multi-collection random images of #{thing.pluralize}",
      description: Faker::Lorem.sentence(20, false, 0).chop,
      # will not be required in future, probably will have a created_at field
      date_created: Time.zone.now.to_s
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(community.id, collection_first.id)
      uo.add_to_path(community.id, collection_last.id)
      uo.save!
    end
  end

  puts 'Database seeded successfully!'
end

