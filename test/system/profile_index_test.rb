require 'application_system_test_case'

class ProfileIndexTest < ApplicationSystemTestCase

  test 'should show basic information about the logged in user' do
    user = users(:regular)
    login_user(user)

    click_link user.name # opens user dropdown which has the profile link
    click_link I18n.t('application.navbar.links.profile')

    assert_selector 'h1', text: user.name
    assert_selector 'dl dd', text: user.email
    assert_selector 'dl dd', text: user.created_at.to_date.to_s

    # Shows draft items
    assert_selector 'h2', text: I18n.t('profile.index.draft_items_header')
    assert_selector '.test-draft-items .list-group-item', count: 2
    assert_selector '.test-draft-items .list-group-item .media-body h4', text: user.draft_items.first.title
    assert_selector '.test-draft-items .list-group-item .media-body h4', text: user.draft_items.last.title

    # # Should not show draft theses
    refute_selector 'h2', text: I18n.t('profile.index.draft_theses_header')
    assert_selector '.test-draft-theses .list-group-item', count: 0

    logout_user
  end

  test 'should show draft theses if available' do
    admin = users(:admin)

    login_user(admin)

    click_link admin.name # opens user dropdown which has the profile link
    click_link I18n.t('application.navbar.links.profile')

    assert_selector 'h1', text: admin.name
    assert_selector 'dl dd', text: admin.email
    assert_selector 'dl dd', text: admin.created_at.to_date.to_s

    # Shows draft items - admin has none so show no items found
    assert_selector 'h2', text: I18n.t('profile.index.draft_items_header')
    assert_selector '.test-draft-items .list-group-item', count: 1
    assert_selector '.test-draft-items .list-group-item', text: 'No items found'

    # # Should show draft theses
    assert_selector 'h2', text: I18n.t('profile.index.draft_theses_header')
    assert_selector '.test-draft-theses .list-group-item', count: 2
    assert_selector '.test-draft-theses .list-group-item .media-body h4', text: admin.draft_theses.first.title
    assert_selector '.test-draft-theses .list-group-item .media-body h4', text: admin.draft_theses.last.title

    logout_user
  end

  test 'should view items owned by logged in user' do
    # Note: searching and faceting is covered more extensively in tests elsewhere
    user = users(:regular)
    admin = users(:admin)

    community = Community.create!(title: 'Fancy Community', owner_id: users(:admin).id)
    collection = Collection.create!(community_id: community.id,
                                    title: 'Fancy Collection', owner_id: users(:admin).id)

    # Two things owned by regular user
    Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
             owner_id: user.id, title: 'Fancy Item',
             creators: ['Joe Blow'],
             created: '2011-11-11',
             languages: [CONTROLLED_VOCABULARIES[:language].english],
             license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
             item_type: CONTROLLED_VOCABULARIES[:item_type].article,
             publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
             subject: ['Fancy things'])
        .tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end
    Thesis.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
               owner_id: user.id, title: 'Nice Item',
               dissertant: 'Joe Blow',
               graduation_date: '2019')
          .tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    # One item owned by admin
    Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
             owner_id: admin.id, title: 'Admin Item',
             creators: ['Joe Blow'],
             created: '1988-08-08',
             languages: [CONTROLLED_VOCABULARIES[:language].english],
             license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
             item_type: CONTROLLED_VOCABULARIES[:item_type].article,
             publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
             subject: ['Ownership'])
        .tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    login_user(user)

    click_link user.name # opens user dropdown which has the profile link
    click_link I18n.t('application.navbar.links.profile')

    # Should be able to find the two items this guy owns
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 2
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item', count: 1

    # Should not be able to find the item owned by admin
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Admin Item'

    # Search items
    fill_in id: 'search_bar', with: 'Fancy'
    click_button 'Search Items'
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item'

    logout_user
  end

end
