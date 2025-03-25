namespace :jupiter do
  desc 'freeze a collection by setting read_only to true'
  task :freeze_collection, [:collection] => :environment do |_t, args|
    collection = Collection.find(args[:collection])
    collection.read_only = true
    collection.save!
  end

  desc 'freeze a set of collections from a file by setting read_only to true'
  task :freeze_collections, [:filename] => :environment do |_t, args|
    File.open(args[:filename]).each do |collection_id|
      collection = Collection.find(collection_id.strip)
      collection.read_only = true
      collection.save!
    end
  end

  desc 'freeze an item by setting read_only to true'
  task :freeze_item, [:item] => :environment do |_t, args|
    item = Item.find(args[:item])
    item.read_only = true
    item.save!
  end

  desc 'unfreeze all collections'
  task :unfreeze_all, [] => :environment do |_t, args|
    Collection.find_each do |collection|
      collection.update!(read_only: false)
    end
  end
end
