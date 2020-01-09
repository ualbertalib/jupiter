Dir[Rails.root.join('lib/extensions/**/*.rb')].sort.each { |f| require f }
