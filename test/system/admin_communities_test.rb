require 'application_system_test_case'

class AdminCommunitiesIndexTest < ApplicationSystemTestCase

  test 'should be able to see rendered markdown of a description for a community' do
    admin = users(:user_admin)
    community = communities(:community_fancy)

    login_user(admin)

    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.communities.index.header')
    assert_selector 'h1', text: I18n.t('admin.communities.index.header')

    # Check for description as markdown
    assert_link('Markdown link', href: 'http://example.com')

    click_link community.title
    assert_selector 'h1', text: community.title

    # Check for description as markdown
    assert_link('Markdown link', href: 'http://example.com')

    logout_user
  end

end
