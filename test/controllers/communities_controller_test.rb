require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Nice community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
  end

  def setup
    sign_in_as users(:admin)
  end

  test 'should get index' do
    get communities_url
    assert_response :success
  end

  test 'should show community' do
    get community_url(@community)
    assert_response :success
  end

  test 'should get new' do
    get new_community_url
    assert_response :success
  end

  context '#create' do
    should 'create community when given valid information' do
      assert_difference('Community.count', +1) do
        post communities_url,
             params: { community: { title: 'New community' } }
      end

      assert_redirected_to community_url(Community.last)
      assert_equal I18n.t('communities.create.created'), flash[:notice]
    end

    should 'not create community when given invalid information' do
      assert_no_difference('Community.count') do
        post communities_url,
             params: { community: { title: '' } }
      end

      assert_response :bad_request
    end
  end

  test 'should get edit' do
    get edit_community_url(@community)
    assert_response :success
  end

  context '#update' do
    should 'update community when given valid information' do
      patch community_url(@community),
            params: { community: { title: 'Updated community' } }

      assert_redirected_to community_url(@community)
      assert_equal I18n.t('communities.update.updated'), flash[:notice]
    end

    should 'not update community when given invalid information' do
      patch community_url(@community),
            params: { community: { title: '' } }

      assert_response :bad_request
    end
  end

  context '#destroy' do
    should 'destroy collection if has no items' do
      community = Community.new_locked_ldp_object(
        title: 'Nice community',
        owner: 1
      ).unlock_and_fetch_ldp_object(&:save!)

      assert_difference('Community.count', -1) do
        delete community_url(community)
      end

      assert_redirected_to admin_communities_and_collections_url
      assert_equal I18n.t('communities.destroy.deleted'), flash[:notice]
    end

    should 'not destroy collection if has items' do
      # Give the community a collection
      Collection.new_locked_ldp_object(
        community_id: @community.id,
        title: 'Nice collection',
        owner: 1
      ).unlock_and_fetch_ldp_object(&:save!)

      assert_no_difference('Collection.count') do
        delete community_url(@community)
      end

      assert_redirected_to admin_communities_and_collections_url
      assert_equal I18n.t('communities.destroy.not_empty_error'), flash[:alert]
    end
  end



end
