require 'application_system_test_case'

class AdminUsersIndexTest < ApplicationSystemTestCase

  test 'should be able to sort columns' do
    admin = users(:user_admin)

    login_user(admin)

    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')

    assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

    click_link I18n.t('admin.users.index.header')

    assert_selector 'h1', text: I18n.t('admin.users.index.header')
    assert_selector 'tbody tr', count: 6

    click_link 'Email' # email ascending

    assert_selector '.fa-sort-down'
    assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

    click_link 'Email' # email descending

    assert_selector '.fa-sort-up' # the rest of this test is flaky without ensuring the page has finished updating
    assert_selector 'tbody tr:last-child th[scope="row"]', text: admin.email

    logout_user
  end

  test 'should be able to autocomplete by email' do
    admin = users(:user_admin)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Autocomplete 'administrator@example.com'
    fill_in I18n.t('search_label'), with: admin.email

    assert_selector 'tbody tr', count: 1
    assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

    logout_user
  end

  test 'should be able to autocomplete by name' do
    admin = users(:user_admin)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Autocomplete 'Administrator'
    fill_in I18n.t('search_label'), with: admin.name

    assert_selector 'div', text: 'Displaying 1 of 1 matching users'
    assert_selector 'tbody tr', count: 1
    assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

    logout_user
  end

  test 'should be able to filter by status' do
    admin = users(:user_admin)
    suspended = users(:user_suspended)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Filter to show user(s) with status of suspended
    select(I18n.t('admin.users.suspended_status'), from: I18n.t('admin.users.status'))

    assert_selector 'tbody tr', count: 1
    assert_selector 'tbody tr:first-child th[scope="row"]', text: suspended.email

    logout_user
  end

  test 'should be able to filter by role' do
    admin = users(:user_admin)
    regular_user = users(:user_regular)
    second_user = users(:user_regular_two)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Filter to show user(s) with role of user
    select(I18n.t('admin.users.user_role'), from: I18n.t('admin.users.role'))

    assert_selector 'tbody tr', count: 4
    assert_selector 'tbody tr th[scope="row"]', text: regular_user.email
    assert_selector 'tbody tr th[scope="row"]', text: second_user.email

    logout_user
  end

end
