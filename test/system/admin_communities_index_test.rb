require 'application_system_test_case'

class AdminCommunitiesIndexTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    2.times do |i|
      Collection.new_locked_ldp_object(title: "Fancy Collection #{i}", owner: 1,
                                       community_id: @community.id)
                .unlock_and_fetch_ldp_object(&:save!)
    end
  end

  # TODO: add more tests
  should 'be able to expand the collection for a community in the list' do
    admin = users(:admin)

    login_user(admin)

    click_link admin.name # opens user dropdown which has the admin link
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.communities.index.header')
    assert_selector 'h1', text: I18n.t('admin.communities.index.header')

    # Initially, collections aren't shown, but there is a 'Collections' link
    refute_link 'Fancy Collection 0'
    refute_link 'Fancy Collection 1'
    refute_button 'Close'
    assert_selector 'a.btn', text: 'Collections'

    # After clicking 'Collections', collections and close button are shown
    click_link 'Collections'
    assert_link 'Fancy Collection 0'
    assert_link 'Fancy Collection 1'
    assert_button 'Close'
    refute_selector 'a.btn', text: 'Collections'

    # Clicking close restores initial state
    click_button 'Close'
    refute_link 'Fancy Collection 0'
    refute_link 'Fancy Collection 1'
    refute_button 'Close'
    assert_selector 'a.btn', text: 'Collections'

    logout_user
  end

end
