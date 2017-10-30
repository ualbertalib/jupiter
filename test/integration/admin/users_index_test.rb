require 'test_helper'

class Admin::UsersIndexTest < ActionDispatch::IntegrationTest

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
    get admin_users_path(format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['id'] }.sort, User.all.map { |u| u['id'] }.sort
    assert_equal json_response.count, User.count
  end

  test 'with query "j" sorted by email' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'j', sort: 'email', direction: 'asc', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['email'] },
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
    get admin_users_path(query: 'jo', sort: 'name', direction: 'desc', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['name'] },
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
    get admin_users_path(query: 'jo', sort: 'name', direction: 'asc', filter: 'active', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['name'] },
                 ['Joe Camel',
                  'John Deere',
                  'John Snow',
                  'Mayor McCheese-Jojoba',
                  'Trader Joe']
  end

  test 'with query "jo", order by role descending, filter by suspended users' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'admin', direction: 'desc', filter: 'suspended', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['name'] },
                 ['Harland Sanders', # admin? = true
                  'Joffrey Baratheon'] # admin? = false
  end

  test 'with query "jo", order by status ascending, filter by admin' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'jo', sort: 'suspended', direction: 'desc', filter: 'admin', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['name'] },
                 ['Harland Sanders', # suspended? = true
                  'Mayor McCheese-Jojoba'] # suspended? = false
  end

  test 'with query "john snow" (space in name)' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'john_', format: :json)
    json_response = JSON.parse(@response.body)
    assert_equal json_response.map { |u| u['name'] }, ['John Snow']
  end

  test 'with query "john_fallafel" (no match)' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: 'john_fallafel', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response, []
  end

  # Wildcards for like
  test 'with query "%"' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: '%', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response, []
  end

  # '_' is a single-character wildcard for SQL 'like' statements
  # We want to confirm that we aren't matching everything, just underscores
  test 'with query "_"' do
    user = users(:admin)
    sign_in_as user
    get admin_users_path(query: '_', sort: 'email', direction: 'asc', format: :json)
    json_response = JSON.parse(@response.body)

    assert_equal json_response.map { |u| u['email'] },
                 ['joffrey_baratheon@example.com',
                  'john_snow@example.com',
                  'tyrion_lannister@example.com']
  end

end
