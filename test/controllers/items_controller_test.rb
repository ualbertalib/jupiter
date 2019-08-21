require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @community = Community.new_locked_ldp_object(title: 'Desolate community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Desolate collection',
                                                   owner: 1)
    @collection.unlock_and_fetch_ldp_object(&:save!)

    @item = Item.new(
      title: 'item to edit',
      owner_id: 1,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      item_type: CONTROLLED_VOCABULARIES[:item_type].book,
      subject: ['Edit']
    ).unlock_and_fetch_ldp_object do |unlocked_item|
      unlocked_item.add_to_path(@community.id, @collection.id)
      unlocked_item.save!
    end

    @thesis = Thesis.new_locked_ldp_object(
      title: 'thesis to edit',
      owner: 1,
      dissertant: 'Joe Blow',
      graduation_date: '2017-03-31',
      visibility: ItemProperties::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.from_now.to_date,
      visibility_after_embargo: CONTROLLED_VOCABULARIES[:visibility].public
    ).unlock_and_fetch_ldp_object do |unlocked_thesis|
      unlocked_thesis.add_to_path(@community.id, @collection.id)
      unlocked_thesis.save!
    end

    @regular_user = users(:regular)
    @admin = users(:admin)
  end

  test 'should be able to show an item' do
    sign_in_as @admin
    get item_url(@item)
    assert_response :success
  end

  test 'should be able to edit an item' do
    sign_in_as @admin
    # test editing of an item.
    get edit_item_url(@item)
    draft_item = DraftItem.drafts.find_by(uuid: @item.id)
    assert_redirected_to item_draft_path(id: Wicked::FIRST_STEP, item_id: draft_item.id)

    # test editing of a thesis.
    get edit_item_url(@thesis)
    draft_thesis = DraftThesis.drafts.find_by(uuid: @thesis.id)
    assert_redirected_to admin_thesis_draft_path(id: Wicked::FIRST_STEP, thesis_id: draft_thesis.id)
  end

  test 'shouldnt be able to edit an item if not owned' do
    sign_in_as @regular_user
    get edit_item_url(@item)
    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized'), flash[:alert]
  end

  test 'shouldnt be able to edit an item if not logged in' do
    get edit_item_url(@item)
    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized_try_logging_in'), flash[:alert]
  end

  test 'should be able to increment and fetch view count' do
    sign_in_as @admin
    assert_equal [0, 0], Statistics.for(item_id: @item.id)
    get item_url(@item)
    assert_equal [1, 0], Statistics.for(item_id: @item.id)
  end

end
