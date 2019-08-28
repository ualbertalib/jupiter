require 'application_system_test_case'

class AdminCommunitiesIndexTest < ApplicationSystemTestCase

  def before_all
    super
    Community.destroy_all
    Collection.destroy_all
    admin = User.find_by(email: 'administrator@example.com')
    @community = Community.create!(title: 'Community', owner_id: admin.id)
    2.times do |i|
      Collection.new(title: "Fancy Collection #{i}", owner_id: admin.id,
                                       community_id: @community.id)
                .save!
    end
  end

  # TODO: add more tests
  test 'should be able to expand the collection for a community in the list' do
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
    find("a[data-community-id='#{@community.id}']", text: 'Collections').click
    assert_link 'Fancy Collection 0'
    assert_link 'Fancy Collection 1'
    assert_button 'Close'
    refute_selector "a.btn[data-community-id='#{@community.id}']", text: 'Collections'

    # Clicking close restores initial state
    click_button 'Close'
    refute_link 'Fancy Collection 0'
    refute_link 'Fancy Collection 1'
    refute_button 'Close'
    assert_selector 'a.btn', text: 'Collections'

    logout_user
  end

end
