require 'test_helper'

class Api::V1::ItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @regular_user = users(:regular)
    @admin = users(:admin)

    @community = Community.create!(title: 'Desolate community', owner_id: @admin.id)
    @collection = Collection.create!(community_id: @community.id, title: 'Desolate collection', owner_id: @admin.id)

    @visible_item = Item.new(
      title: 'item to edit',
      owner_id: users(:regular).id,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      item_type: CONTROLLED_VOCABULARIES[:item_type].book,
      subject: ['Edit']
    ).tap do |unlocked_item|
      unlocked_item.add_to_path(@community.id, @collection.id)
      unlocked_item.save!
    end

    @private_item = Item.new(
      title: 'item to edit',
      owner_id: users(:admin).id,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PRIVATE,
      item_type: CONTROLLED_VOCABULARIES[:item_type].book,
      subject: ['Edit']
    ).tap do |unlocked_item|
      unlocked_item.add_to_path(@community.id, @collection.id)
      unlocked_item.save!
    end   
  end

  test 'should be able to show a visible item' do
    sign_in_as @regular_user
    get api_v1_item_url(@visible_item)
    assert_response :success
  end

  test 'should not be able to show a private item' do
    sign_in_as @regular_user
    get api_v1_item_url(@private_item)
    assert_response :redirect
  end

end