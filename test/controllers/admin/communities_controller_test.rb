require 'test_helper'

class Admin::CommunitiesControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new(title: 'Nice community',
                                                 owner_id: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
  end

  def setup
    sign_in_as users(:admin)
  end

  test 'should get index' do
    get admin_communities_url
    assert_response :success
  end

  test 'should show community' do
    get admin_community_url(@community)
    assert_response :success
  end

  test 'should get new' do
    get new_admin_community_url
    assert_response :success
  end

  test 'should create community when given valid information' do
    assert_difference('Community.count', +1) do
      post admin_communities_url,
           params: { community: { title: 'New community' } }
    end

    assert_redirected_to admin_community_url(Community.last)
    assert_equal I18n.t('admin.communities.create.created'), flash[:notice]
  end

  test 'should not create community when given invalid information' do
    assert_no_difference('Community.count') do
      post admin_communities_url,
           params: { community: { title: '' } }
    end

    assert_response :bad_request
  end

  test 'should get edit' do
    get edit_admin_community_url(@community)
    assert_response :success
  end

  test 'should update community when given valid information' do
    patch admin_community_url(@community),
          params: { community: { title: 'Updated community' } }

    assert_redirected_to admin_community_url(@community)
    assert_equal I18n.t('admin.communities.update.updated'), flash[:notice]
  end

  test 'should not update community when given invalid information' do
    patch admin_community_url(@community),
          params: { community: { title: '' } }

    assert_response :bad_request
  end

  test 'should destroy collection if has no items' do
    community = Community.new(
      title: 'Nice community',
      owner_id: 1
    ).unlock_and_fetch_ldp_object(&:save!)

    assert_difference('Community.count', -1) do
      delete admin_community_url(community)
    end

    assert_redirected_to admin_communities_url
    assert_equal I18n.t('admin.communities.destroy.deleted'), flash[:notice]
  end

  test 'should not destroy collection if has items' do
    # Give the community a collection
    Collection.new(
      community_id: @community.id,
      title: 'Nice collection',
      owner_id: 1
    ).unlock_and_fetch_ldp_object(&:save!)

    assert_no_difference('Collection.count') do
      delete admin_community_url(@community)
    end

    assert_redirected_to admin_communities_url

    assert_match I18n.t('activerecord.errors.models.community.attributes.member_collections.must_be_empty',
                        list_of_collections: @community.member_collections.map(&:title).join(', ')), flash[:alert]
  end

end
