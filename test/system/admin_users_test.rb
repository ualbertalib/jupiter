require 'application_system_test_case'

class AdminUsersTest < ApplicationSystemTestCase

  context 'Admin users index page' do
    should 'be able to sort columns' do
      admin = users(:admin)

      login_as_user(admin)

      click_link admin.name # opens user dropdown which has the admin link
      click_link I18n.t('application.navbar.links.admin')

      assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

      click_link I18n.t('admin.users.index.header')
      assert_selector 'h1', text: I18n.t('admin.users.index.header')
      assert_selector 'tbody tr', count: 4
      assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

      click_link 'Email'

      assert_selector 'tbody tr:last-child th[scope="row"]', text: admin.email
    end

    should 'be able to autocomplete a user' do
      admin = users(:admin)

      login_as_user(admin)

      click_link admin.name # opens user dropdown which has the admin link
      click_link I18n.t('application.navbar.links.admin')
      click_link I18n.t('admin.users.index.header')

      # Suggestions only appear when there is text
      assert_selector '.tt-suggestion', count:0
      fill_in name: 'query', with: 'ad'
      assert_selector '.tt-suggestion', count:1, text: "#{admin.name} (#{admin.email})"

      # Clicking a suggestion takes you to the page for the user
      find('.tt-suggestion').click
      assert_equal URI.parse(current_url).path, admin_user_path(admin)
    end
  end

  context 'Admin users show page' do
    should 'not be able to toggle suspended/admin or impersonate yourself' do
      admin = users(:admin)

      login_as_user(admin)

      click_link admin.name # opens user dropdown which has the admin link
      click_link I18n.t('application.navbar.links.admin')

      assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

      click_link I18n.t('admin.users.index.header')
      assert_selector 'h1', text: I18n.t('admin.users.index.header')
      assert_selector 'tbody tr', count: 4
      assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

      click_link admin.email

      assert_selector 'h1', text: admin.name

      # shouldn't be any toggle suspend/admin or impersonate buttons on this page
      refute_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_text')
      refute_selector :link, text: I18n.t('admin.users.show.impersonate_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')
    end

    should 'be able to toggle suspended/admin a regular user' do
      admin = users(:admin)
      user = users(:regular_user)

      login_as_user(admin)

      click_link admin.name # opens user dropdown which has the admin link
      click_link I18n.t('application.navbar.links.admin')

      assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

      click_link I18n.t('admin.users.index.header')
      assert_selector 'h1', text: I18n.t('admin.users.index.header')
      assert_selector 'tbody tr', count: 4
      assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

      click_link user.email

      assert_selector 'h1', text: user.name

      assert_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')

      accept_confirm do
        click_link I18n.t('admin.users.show.grant_admin_link_text')
      end

      assert_text I18n.t('admin.users.show.grant_admin_flash', user: user.name)
      assert_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')

      accept_confirm do
        click_link I18n.t('admin.users.show.revoke_admin_link_text')
      end

      assert_text I18n.t('admin.users.show.revoke_admin_flash', user: user.name)
      assert_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')

      accept_confirm do
        click_link I18n.t('admin.users.show.suspend_link_text')
      end

      assert_text I18n.t('admin.users.show.suspend_flash', user: user.name)
      assert_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')

      accept_confirm do
        click_link I18n.t('admin.users.show.unsuspend_link_text')
      end

      assert_text I18n.t('admin.users.show.unsuspend_flash', user: user.name)
      assert_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')
    end

    should 'be able to impersonate a regular user' do
      admin = users(:admin)
      user = users(:regular_user)

      login_as_user(admin)

      click_link admin.name # opens user dropdown which has the admin link
      click_link I18n.t('application.navbar.links.admin')

      assert_selector 'h1', text: I18n.t('admin.dashboard.index.header')

      click_link I18n.t('admin.users.index.header')
      assert_selector 'h1', text: I18n.t('admin.users.index.header')
      assert_selector 'tbody tr', count: 4
      assert_selector 'tbody tr:first-child th[scope="row"]', text: admin.email

      click_link user.email

      assert_selector 'h1', text: user.name

      assert_selector :link, text: I18n.t('admin.users.show.suspend_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.grant_admin_link_text')
      assert_selector :link, text: I18n.t('admin.users.show.impersonate_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.unsuspend_link_text')
      refute_selector :link, text: I18n.t('admin.users.show.revoke_admin_link_text')

      accept_confirm do
        click_link I18n.t('admin.users.show.impersonate_link_text')
      end

      # we signed in as user and have been redirected to homepage
      assert_text I18n.t('admin.users.show.impersonate_flash', user: user.name)
      assert_text user.name
      assert_selector 'h1', text: I18n.t('welcome.index.header')

      # we stop impersonation and get redirected back to admin user show page
      click_link user.name # opens user dropdown which has the stop impersonating link
      click_link I18n.t('application.navbar.links.stop_impersonating')
      assert_text I18n.t('sessions.stop_impersonating.flash', original_user: user.name)
      assert_selector 'h1', text: user.name
    end
  end

end
