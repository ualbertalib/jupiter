require 'test_helper'

class ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @regular_user = users(:regular)
    @admin = users(:admin)
    @community = communities(:books)
    @collection = collections(:fantasy_books)

    @item = Item.new(
      title: 'item to edit',
      owner_id: @admin.id,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [ControlledVocabulary.era.language.english],
      license: ControlledVocabulary.era.license.attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_PUBLIC,
      item_type: ControlledVocabulary.era.item_type.book,
      subject: ['Edit']
    ).tap do |unlocked_item|
      unlocked_item.add_to_path(@community.id, @collection.id)
      unlocked_item.save!
    end

    @thesis = Thesis.new(
      title: 'thesis to edit',
      owner_id: @admin.id,
      dissertant: 'Joe Blow',
      graduation_date: '2017-03-31',
      visibility: JupiterCore::Depositable::VISIBILITY_EMBARGO,
      embargo_end_date: 2.days.from_now.to_date,
      visibility_after_embargo: ControlledVocabulary.jupiter_core.visibility.public
    ).tap do |unlocked_thesis|
      unlocked_thesis.add_to_path(@community.id, @collection.id)
      unlocked_thesis.save!
    end
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
    draft_item = DraftItem.find_by(uuid: @item.id)
    assert_redirected_to item_draft_path(id: Wicked::FIRST_STEP, item_id: draft_item.id)

    # test editing of a thesis.
    get edit_item_url(@thesis)
    draft_thesis = DraftThesis.find_by(uuid: @thesis.id)
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
