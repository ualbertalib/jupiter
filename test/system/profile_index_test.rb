require 'application_system_test_case'

class ProfileIndexTest < ApplicationSystemTestCase

  should 'show basic information about the logged in user' do
    user = users(:regular_user)

    login_user(user)

    click_link user.name # opens user dropdown which has the profile link
    click_link I18n.t('application.navbar.links.profile')

    assert_selector 'h1', text: user.name
    assert_selector 'dl dd', text: user.email
    assert_selector 'dl dd', text: user.created_at.to_date.to_s

    logout_user
  end

  should 'view items owned by logged in user' do
    # Note: searching and faceting is covered more extensively in tests elsewhere
    user = User.find_by(email: 'john_snow@example.com')
    admin = users(:admin)

    community = Community.new_locked_ldp_object(title: 'Fancy Community', owner: 1)
                         .unlock_and_fetch_ldp_object(&:save!)
    collection = Collection.new_locked_ldp_object(community_id: community.id,
                                                  title: 'Fancy Collection', owner: 1)
                           .unlock_and_fetch_ldp_object(&:save!)

    # Two items owned by regular user
    ['Fancy', 'Nice'].each do |adjective|
      Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                 owner: user.id, title: "#{adjective} Item",
                                 creators: ['Joe Blow'],
                                 languages: [CONTROLLED_VOCABULARIES[:language].eng],
                                 license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                 item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                 publication_status: CONTROLLED_VOCABULARIES[:publication_status].published,
                                 subject: [adjective])
          .unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end
    end
    # One item owned by admin
    Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC,
                               owner: admin.id, title: 'Admin Item',
                               creators: ['Joe Blow'],
                               languages: [CONTROLLED_VOCABULARIES[:language].eng],
                               license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                               item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                               publication_status: CONTROLLED_VOCABULARIES[:publication_status].published,
                               subject: ['Ownership'])
        .unlock_and_fetch_ldp_object do |uo|
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
    fill_in name: 'query', with: 'Fancy'
    click_button 'Search Items'
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item'

    logout_user
  end

end
