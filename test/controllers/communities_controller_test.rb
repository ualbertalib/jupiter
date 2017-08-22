require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    sign_in_as @admin

    # TODO: setup proper fixtures for LockedLdpObjects
    @community = Community.new_locked_ldp_object(title: 'Nice book',
                                                 owner: @admin.id)
    @community.unlock_and_fetch_ldp_object(&:save!)
  end

  test 'should get index' do
    get communities_url
    assert_response :success
  end

  test 'should get new' do
    get new_community_url
    assert_response :success
  end

  test 'should create community' do
    assert_difference('Community.count') do
      post communities_url, params: { community: { title: 'New Book' } }
    end

    # TODO: implement a method to fetch most recently created, e.g. 'last'
    # assert_redirected_to community_url(Community.last)
  end

  test 'should show community' do
    get community_url(@community)
    assert_response :success
  end

  test 'should get edit' do
    get edit_community_url(@community)
    assert_response :success
  end

  test 'should update community' do
    patch community_url(@community), params: { community: { title: 'Updated Book' } }
    assert_redirected_to community_url(@community)
  end

  test 'should destroy community' do
    assert_difference('Community.count', -1) do
      delete community_url(@community)
    end

    assert_redirected_to admin_communities_and_collections_url
  end

end
