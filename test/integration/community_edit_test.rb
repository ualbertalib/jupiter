require 'test_helper'

class CommunityEditTest < ActionDispatch::IntegrationTest

  def before_all
    super

    # TODO: setup proper fixtures for LockedLdpObjects

    # A community with a logo
    @community1 = Community
                  .new_locked_ldp_object(title: 'Two collection community', owner: 1)
                  .unlock_and_fetch_ldp_object(&:save!)
    @community1.logo.attach io: File.open(file_fixture('image-sample.jpeg')),
                            filename: 'image-sample.jpeg', content_type: 'image/jpeg'

    # A community with no collections, no logo
    @community2 = Community
                  .new_locked_ldp_object(title: 'Empty community', owner: 1)
                  .unlock_and_fetch_ldp_object(&:save!)
  end

  test 'visiting the edit page for a community with a logo as an admin' do
    user = users(:admin)
    sign_in_as user
    get edit_admin_community_url(@community1)

    # Logo should be shown
    assert_select 'img.img-thumbnail', count: 1
    assert_select 'div.img-thumbnail i.fa', count: 0

    # Upload button should be shown
    assert_select 'input[type="file"][name="community[logo]"]', count: 1

    # Logo remove button should be shown
    assert_select 'input[type="checkbox"][name="community[remove_logo]"]', count: 1
  end

  test 'visiting edit page of a community with no logo' do
    user = users(:admin)
    sign_in_as user
    get edit_admin_community_url(@community2)

    # Logo should not be shown
    assert_select 'img.img-thumbnail', count: 0
    assert_select 'div.img-thumbnail i.fa', count: 1

    # Upload button should be shown
    assert_select 'input[type="file"][name="community[logo]"]', count: 1

    # Logo remove button should not be shown
    assert_select 'input[type="checkbox"][name="community[remove_logo]"]', count: 0
  end

  test 'visiting the edit page for a community as a regular user' do
    user = users(:regular)
    sign_in_as user

    # Should return 404
    assert_raises ActionController::RoutingError do
      get edit_admin_community_url(@community1)
    end
  end

end
