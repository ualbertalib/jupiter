require 'application_system_test_case'

class AdminItemsIndexTest < ApplicationSystemTestCase

  test 'should be able to view all items/theses owned by anybody' do
    # NOTE: searching and faceting is covered more extensively in tests elsewhere
    admin = users(:admin)

    # creating the index from the fixtures requires a save
    # TODO: these would be good candidates for using factories instead.
    items(:fancy).save
    items(:admin).save
    thesis(:nice).save

    login_user(admin)

    click_link admin.name
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.items.index.header')

    # Should be able to find the three items
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 3
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a',
                    text: 'dcterms:title1$ Some Title for Item', count: 1

    # Search items
    fill_in id: 'search_bar', with: 'Fancy'
    click_button 'Search Items'
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 1
    assert_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Fancy Item', count: 1
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a', text: 'Nice Item'
    refute_selector 'div.jupiter-results-list li.list-group-item .media-body a',
                    text: 'dcterms:title1$ Some Title for Item', count: 1

    logout_user
  end

end
