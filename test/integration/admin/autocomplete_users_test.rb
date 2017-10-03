require 'test_helper'

class Admin::AutocompleteUsersTest < ActionDispatch::IntegrationTest
  def setup
    super
    # These get mixed with the fixtures
    User.create([{ name: 'John Deere', email: 'juser.1@example.com', admin: false },
                 { name: 'Joe Camel', email: 'foo@example.com', admin: false},
                 { name: 'Mayor McCheese-Jojoba', email: 'what@example.com', admin: false},
                 { name: 'Burger King', email: 'why@example.com', admin: false},
                 { name: 'Dave Thomas', email: 'jumbalaya@example.com', admin: false},
                 { name: 'Tim Horton', email: 'nope@example.com', admin: false},
                 { name: 'Trader Joe', email: 'lol@example.com', admin: false},
                 { name: 'Harland Sanders', email: 'that.joker@example.com', admin: false}])
  end

  test 'with query "j"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: 'j')
    output = JSON.parse(response.body)
    name_emails = output.map { |user| user['name_email'] }.sort
    assert_equal name_emails, ["Dave Thomas (jumbalaya@example.com)",
                               "Joe Camel (foo@example.com)",
                               "Joffrey Baratheon (joffrey_baratheon@example.com)",
                               "John Deere (juser.1@example.com)",
                               "John Snow (john_snow@example.com)",
                               "Mayor McCheese-Jojoba (what@example.com)",
                               "Trader Joe (lol@example.com)"]
  end

  test 'with query "jo"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: 'jo')
    output = JSON.parse(response.body)
    name_emails = output.map { |user| user['name_email'] }.sort
    assert_equal name_emails, ["Joe Camel (foo@example.com)",
                               "Joffrey Baratheon (joffrey_baratheon@example.com)",
                               "John Deere (juser.1@example.com)",
                               "John Snow (john_snow@example.com)",
                               "Mayor McCheese-Jojoba (what@example.com)",
                               "Trader Joe (lol@example.com)"]
  end

  test 'with query "john_"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: 'john_')
    output = JSON.parse(response.body)
    assert_equal output.count, 1
    assert_equal output.first['name_email'], 'John Snow (john_snow@example.com)'
    # John Snow corresponds to the fixture :regular_user
    assert_equal output.first['url'], admin_user_path(users(:regular_user))
  end

  test 'with query "john_s"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: 'john_s')
    output = JSON.parse(response.body)
    assert_equal output.count, 1
    assert_equal output.first['name_email'], 'John Snow (john_snow@example.com)'
    # John Snow corresponds to the fixture :regular_user
    assert_equal output.first['url'], admin_user_path(users(:regular_user))
  end

  test 'with query "john_fallafel"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: 'john_fallafel')
    output = JSON.parse(response.body)
    assert_equal output.count, 0
  end

  # Wildcards for like
  test 'with query "%"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: '%')
    output = JSON.parse(response.body)
    assert_equal output.count, 0
  end

  test 'with query "_"' do
    user = users(:admin)
    sign_in_as user
    get autocomplete_admin_users_path(query: '_')
    output = JSON.parse(response.body)
    assert_equal output.count, 0
  end

end
