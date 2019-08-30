require 'application_system_test_case'

class AdminItemsIndexTest < ApplicationSystemTestCase

  test 'should be able to view all items/theses owned by anybody' do
    # Note: searching and faceting is covered more extensively in tests elsewhere
    user = users(:regular)
    admin = User.find_by(email: 'administrator@example.com')

    community = Community.create!(title: 'Fancy Community', owner_id: admin.id)
    collection = Collection.create!(community_id: community.id,
                                    title: 'Fancy Collection', owner_id: admin.id)

    # Two things owned by regular user
    Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
             owner_id: user.id, title: 'Fancy Item',
             creators: ['Joe Blow'],
             created: 'Fall 2017',
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
             created: 'Winter 2017',
             languages: [CONTROLLED_VOCABULARIES[:language].english],
             license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
             item_type: CONTROLLED_VOCABULARIES[:item_type].article,
             publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
             subject: ['Ownership'])
        .tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    login_user(admin)

    click_link admin.name
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.items.index.header')

    # Should be able to find the three items
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 3
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Admin Item', count: 1

    # Search items
    fill_in id: 'search_bar', with: 'Fancy'
    click_button 'Search Items'
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item'
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Admin Item'

    logout_user
  end

end
