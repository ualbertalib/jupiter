namespace :jupiter do
  desc 'freeze a collection by setting read_only to true'
  task :freeze_collection, [:collection] => :environment do |_t, args|
    puts 'started freezing collection'
    collection = Collection.find(args[:collection])
      collection.read_only = true
      collection.save!
      puts 'finished freezing collection'
  end

  desc 'freeze a set of collections from a file by setting read_only to true'
  task :freeze_collections, [:filename] => :environment do |_t, args|
    puts 'started freezing collections'
      File.open(args[:filename]).each do |collection_id|
        collection = Collection.find(collection_id.strip)
        collection.read_only = true
        collection.save!
        print '.'
      end
      puts 'finished freezing collections'
  end

  desc 'freeze an item by setting read_only to true'
  task :freeze_item, [:item] => :environment do |_t, args|
    puts 'started freezing item'
    item = begin
      Item.find(args[:item])
    rescue ActiveRecord::RecordNotFound
      Thesis.find(args[:item])
    end
    item.read_only = true
    item.save!
    puts 'finished freezing item'
  end

  desc 'unfreeze all collections'
  task :unfreeze_all, [] => :environment do |_t, _args|
    # specifically use update_columns to skip validations and avoid performance issues
    # rubocop:disable Rails/SkipsModelValidations
    puts 'started unfreezing collections'
      Collection.where(read_only: true).find_each do |collection|
        collection.update_columns(read_only: false)
        print '.'
      end
      puts 'finished unfreezing collections'
      puts 'started unfreezing items'
      Item.where(read_only: true).find_each do |item|
        item.update_columns(read_only: false)
        print '.'
      end
      puts 'finished unfreezing items'
    # rubocop:enable Rails/SkipsModelValidations
  end
end
