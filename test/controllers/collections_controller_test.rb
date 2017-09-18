require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Nice community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Nice collection',
                                                   owner: 1)
    @collection.unlock_and_fetch_ldp_object(&:save!)
  end

  def setup
    @admin = users(:admin)
    sign_in_as @admin
  end

  # Note: this controller has no #index action

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

  test 'should get new' do
    get new_community_collection_url(@community)
    assert_response :success
  end

  context '#create' do
    should 'create collection when given valid information' do
      assert_difference('Collection.count', +1) do
        post community_collections_url(@community),
             params: { collection: { title: 'New collection' } }
      end

      assert_redirected_to community_collection_url(@community, Collection.last)
      assert_equal I18n.t('collections.create.created'), flash[:notice]
    end

    should 'not create collection when given invalid information' do
      assert_no_difference('Collection.count') do
        post community_collections_url(@community),
             params: { collection: { title: '' } }
      end

      assert_response :bad_request
    end
  end

  test 'should get edit' do
    get edit_community_collection_url(@community, @collection)
    assert_response :success
  end

  context '#update' do
    should 'update collection when given valid information' do
      patch community_collection_url(@community, @collection),
            params: { collection: { title: 'Updated collection' } }

      assert_redirected_to admin_communities_and_collections_url
      assert_equal I18n.t('collections.update.updated'), flash[:notice]
    end

    should 'not update collection when given invalid information' do
      patch community_collection_url(@community, @collection),
            params: { collection: { title: '' } }

      assert_response :bad_request
    end
  end

  context '#destroy' do
    should 'destroy collection if has no items' do
      community = Community.new_locked_ldp_object(
        title: 'Nice community',
        owner: 1
      ).unlock_and_fetch_ldp_object(&:save!)

      collection = Collection.new_locked_ldp_object(
        community_id: @community.id,
        title: 'Nice collection',
        owner: 1
      ).unlock_and_fetch_ldp_object(&:save!)

      assert_difference('Collection.count', -1) do
        delete community_collection_url(community, collection)
      end

      assert_redirected_to admin_communities_and_collections_url
      assert_equal I18n.t('collections.destroy.deleted'), flash[:notice]
    end

    should 'not destroy collection if has items' do
      # Give the collection an item
      Item.new_locked_ldp_object(
        owner: 1,
        visibility: JupiterCore::VISIBILITY_PRIVATE
      ).unlock_and_fetch_ldp_object do |unlocked_item|
        unlocked_item.add_to_path(@community.id, @collection.id)
        unlocked_item.save!
      end

      assert_no_difference('Collection.count') do
        delete community_collection_url(@community, @collection)
      end

      assert_redirected_to admin_communities_and_collections_url
      assert_equal I18n.t('collections.destroy.not_empty_error'), flash[:alert]
    end
  end

end
