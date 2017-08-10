# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


if Rails.env.development?
  puts 'Starting seeding of dev database...'

  # Seed an admin user
  unless User.find_by(email: 'admin@ualberta.ca')
    admin = User.create(name: 'Admin', email: 'admin@ualberta.ca', admin: true)
    admin.identities.create(provider: 'developer', uid: 'admin@ualberta.ca')
  end

  puts 'Database seeded successfully!'
end
