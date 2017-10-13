require 'test_helper'

class Admin::IndexTest < ActionDispatch::IntegrationTest

  def setup
    super
    # These get mixed with the existing fixtures
    User.create([{ name: 'John Deere', email: 'juser.1@example.com', admin: false, suspended: false },
                 { name: 'Joe Camel', email: 'foo@example.com', admin: false, suspended: false },
                 { name: 'Mayor McCheese-Jojoba', email: 'what@example.com', admin: true, suspended: false },
                 { name: 'Burger King', email: 'why@example.com', admin: true, suspended: false },
                 { name: 'Dave Thomas', email: 'jumbalaya@example.com', admin: false, suspended: false },
                 { name: 'Tim Horton', email: 'nope@example.com', admin: false, suspended: false },
                 { name: 'Trader Joe', email: 'lol@example.com', admin: false, suspended: false },
                 { name: 'Harland Sanders', email: 'that.joker@example.com', admin: true, suspended: true }])
  end

  test 'with no query' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path
    assert_equal assigns[:users].sort, User.all.sort
    assert_equal assigns[:users].count, 12
  end

  test 'with query "j" regular sort' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'j')

    assert_equal assigns[:users].map(&:email),
                 ['foo@example.com',
                  'joffrey_baratheon@example.com',
                  'john_snow@example.com',
                  'jumbalaya@example.com',
                  'juser.1@example.com',
                  'lol@example.com',
                  'that.joker@example.com',
                  'what@example.com']
  end

  test 'with query "jo", sort by name descending' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'name', direction: 'desc')

    assert_equal assigns[:users].map(&:name),
                 ['Trader Joe',
                  'Mayor McCheese-Jojoba',
                  'John Snow',
                  'John Deere',
                  'Joffrey Baratheon',
                  'Joe Camel',
                  'Harland Sanders']
  end

  test 'with query "jo", order by name ascending, filter by active users' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'name', direction: 'asc', filter: 'active')
    assert_equal assigns[:users].map(&:name),
                 ['Joe Camel',
                  'John Deere',
                  'John Snow',
                  'Mayor McCheese-Jojoba',
                  'Trader Joe']
  end

  test 'with query "jo", order by role descending, filter by suspended users' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'is_admin', direction: 'desc', filter: 'suspended')
    assert_equal assigns[:users].map(&:name),
                 ['Harland Sanders', # is_admin = true
                  'Joffrey Baratheon'] # is_admin = false
  end

  test 'with query "jo", order by status ascending, filter by admin' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'is_suspended', direction: 'asc', filter: 'admin')
    assert_equal assigns[:users].map(&:name),
                 ['Harland Sanders', # is_suspended = true
                  'Mayor McCheese-Jojoba'] # is_suspended = false
  end

  test 'with query "john snow" (space in name)' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'john_')
    assert_equal assigns[:users].map(&:name), ['John Snow']
  end

  test 'with query "john_fallafel" (no match)' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'john_fallafel')
    assert_equal assigns[:users], []
  end

  # Wildcards for like
  test 'with query "%"' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: '%')
    assert_equal assigns[:users], []
  end

  # '_' is a single-character wildcard for SQL 'like' statements
  # We want to confirm that we aren't matching everything, just underscores
  test 'with query "_"' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: '_')
    assert_equal assigns[:users].map(&:email),
                 ['joffrey_baratheon@example.com',
                  'john_snow@example.com',
                  'tyrion_lannister@example.com']
  end

end
