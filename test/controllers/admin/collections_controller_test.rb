require 'test_helper'

class Admin::CollectionsControllerTest < ActionDispatch::IntegrationTest

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

  test 'should show collection' do
    get admin_community_collection_url(@community, @collection)
    assert_response :success
  end

  test 'should get new' do
    get new_admin_community_collection_url(@community)
    assert_response :success
  end

  test 'should create collection when given valid information' do
    assert_difference('Collection.count', +1) do
      post admin_community_collections_url(@community),
           params: { collection: { title: 'New collection' } }
    end

    assert_redirected_to admin_community_collection_url(@community, Collection.last)
    assert_equal I18n.t('admin.collections.create.created'), flash[:notice]
  end

  test 'should not create collection when given invalid information' do
    assert_no_difference('Collection.count') do
      post admin_community_collections_url(@community),
           params: { collection: { title: '' } }
    end

    assert_response :bad_request
  end

  test 'should get edit' do
    get edit_admin_community_collection_url(@community, @collection)
    assert_response :success
  end

  test 'update collection when given valid information' do
    patch admin_community_collection_url(@community, @collection),
          params: { collection: { title: 'Updated collection' } }

    assert_redirected_to admin_community_collection_url(@community, @collection)
    assert_equal I18n.t('admin.collections.update.updated'), flash[:notice]
  end

  test 'should not update collection when given invalid information' do
    patch admin_community_collection_url(@community, @collection),
          params: { collection: { title: '' } }

    assert_response :bad_request
  end

  test 'should destroy collection if has no items' do
    collection = Collection.new_locked_ldp_object(
      community_id: @community.id,
      title: 'Nice collection',
      owner: 1
    ).unlock_and_fetch_ldp_object(&:save!)

    assert_difference('Collection.count', -1) do
      delete admin_community_collection_url(@community, collection)
    end

    assert_redirected_to admin_community_url(@community)
    assert_equal I18n.t('admin.collections.destroy.deleted'), flash[:notice]
  end

  test 'should not destroy collection if has items' do
    collection = Collection.new_locked_ldp_object(
      community_id: @community.id,
      title: 'Nice collection',
      owner: 1
    ).unlock_and_fetch_ldp_object(&:save!)

    # Give the collection an item
    Item.new_locked_ldp_object(
      title: 'item blocking deletion',
      owner: 1,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PRIVATE,
      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
      subject: ['Invincibility']
    ).unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(@community.id, collection.id)
      unlocked_item.save!
    end

    assert_no_difference('Collection.count') do
      delete admin_community_collection_url(@community, collection)
    end

    assert_redirected_to admin_community_url(@community)

    assert_match I18n.t('activemodel.errors.models.ir_collection.attributes.member_objects.must_be_empty',
                        list_of_objects: collection.member_objects.map(&:title).join(', ')), flash[:alert]
  end

  test 'should not destroy collection if has theses' do
    collection = Collection.new_locked_ldp_object(
      community_id: @community.id,
      title: 'Nice collection',
      owner: 1
    ).unlock_and_fetch_ldp_object(&:save!)

    Thesis.new_locked_ldp_object(
      title: 'thesis blocking deletion',
      owner: 1,
      dissertant: 'Joe Blow',
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      graduation_date: '2017-03-31'
    ).unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(@community.id, collection.id)
      unlocked_item.save!
    end

    assert_no_difference('Collection.count') do
      delete admin_community_collection_url(@community, collection)
    end

    assert_redirected_to admin_community_url(@community)

    assert_match I18n.t('activemodel.errors.models.ir_collection.attributes.member_objects.must_be_empty',
                        list_of_objects: collection.member_objects.map(&:title).join(', ')), flash[:alert]
  end

end
