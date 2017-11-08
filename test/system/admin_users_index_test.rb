require 'application_system_test_case'

class AdminUsersIndexTest < ApplicationSystemTestCase

  should 'be able to sort columns' do
    admin = users(:admin)

    login_user(admin)

    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')

    assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

    click_link I18n.t('admin.users.index.header')
    assert_selector 'h1', text: I18n.t('admin.users.index.header')
    assert_selector 'tbody tr', count: 4

    click_link 'Email' # email ascending

    assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

    click_link 'Email' # email descending

    assert_selector 'tbody tr:last-child th[scope="row"]', text: admin.email

    logout_user
  end

  should 'be able to autocomplete by email' do
    admin = users(:admin)

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

  should 'be able to autocomplete by name' do
    admin = users(:admin)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Autocomplete 'Administrator'
    fill_in I18n.t('search_label'), with: admin.name
    assert_selector 'tbody tr', count: 1
    assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

    logout_user
  end

  should 'be able to filter by status' do
    admin = users(:admin)
    suspended = users(:suspended_user)

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

  should 'be able to filter by role' do
    admin = users(:admin)
    regular = users(:regular_user)
    suspended = users(:suspended_user)

    login_user(admin)
    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.users.index.header')

    # Filter to show user(s) with role of user
    select(I18n.t('admin.users.user_role'), from: I18n.t('admin.users.role'))
    assert_selector 'tbody tr', count: 2
    assert_selector 'tbody tr:first-child th[scope="row"]', text: suspended.email
    assert_selector 'tbody tr:last-child th[scope="row"]', text: regular.email

    logout_user
  end

end
