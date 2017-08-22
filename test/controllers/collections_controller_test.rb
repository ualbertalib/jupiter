require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    sign_in_as @admin

    # TODO: setup proper fixtures for LockedLdpObjects
    @community = Community.new_locked_ldp_object(title: 'Nice community',
                                                 owner: @admin.id)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Nice collection',
                                                   owner: @admin.id)
    @collection.unlock_and_fetch_ldp_object(&:save!)
  end

  # Note: this controller has no #index action

  test 'should get new' do
    get new_community_collection_url(@community)
    assert_response :success
  end

  test 'should create collection' do
    assert_difference('Collection.count') do
      post community_collections_url(@community),
           params: { collection: { title: 'New collection' } }
    end

    # TODO: implement a method to fetch most recently created, e.g. 'last'
    # assert_redirected_to collection_url(Collection.last)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

  test 'should get edit' do
    get edit_community_collection_url(@community, @collection)
    assert_response :success
  end

  test 'should update collection' do
    patch community_collection_url(@community, @collection),
          params: { collection: { title: 'Updated collection' } }
    # TODO: do smart routing based on the path that got us here
    # assert_redirected_to collection_url(@collection)
    assert_redirected_to admin_communities_and_collections_url
  end

  test 'should destroy collection' do
    assert_difference('Collection.count', -1) do
      delete community_collection_url(@community, @collection)
    end

    assert_redirected_to admin_communities_and_collections_url
  end

end
