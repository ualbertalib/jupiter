require 'application_system_test_case'

class CollectionsPaginationAndSortTest < ApplicationSystemTestCase

  setup do
    admin = users(:user_admin)
    @community = communities(:community_with_no_collections)
    # For sorting, creation order is 'Fancy Collection 00', 'Nice Collection 01', 'Fancy Collection 02', etc. ...
    11.times do |i|
      Collection.create!(title: format("#{random_title(i)} Collection %02i", i), owner_id: admin.id,
                         community_id: @community.id)
    end
  end

  test 'anybody should be able to sort and paginate collections' do
    visit community_path(@community)

    assert_selector 'div', text: '1 - 10 of 11'
    # Default sort is by title. First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'ul.list-group li:nth-child(2) a', text: 'Fancy Collection 02'
    assert_selector 'ul.list-group li:nth-child(9) a', text: 'Nice Collection 05'
    # Would like to use 'last-child' here, but for some reason it's not working
    assert_selector 'ul.list-group li:nth-child(10) a', text: 'Nice Collection 07'

    # The last one should be on next page
    refute_selector 'a', text: 'Nice Collection 09'
    click_link 'Next'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Nice Collection 09'
  end

  test 'sort by descending alphabetical order and paginate collections' do
    visit community_path(@community)
    click_button 'Sort by'

    assert_selector 'a', text: 'Title (A-Z)'
    assert_selector 'a', text: 'Title (Z-A)'
    assert_selector 'a', text: 'Date (newest first)'
    assert_selector 'a', text: 'Date (oldest first)'

    # Reverse sort
    click_link 'Title (Z-A)'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'desc')
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'button', text: 'Title (Z-A)'
    assert_selector 'ul.list-group li:first-child a', text: 'Nice Collection 09'
    assert_selector 'ul.list-group li:nth-child(2) a', text: 'Nice Collection 07'
    assert_selector 'ul.list-group li:nth-child(9) a', text: 'Fancy Collection 04'
    assert_selector 'ul.list-group li:nth-child(10) a', text: 'Fancy Collection 02'

    # The first 'Fancy' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 00'
    click_link 'Next'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'desc',
                                                                                page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 00'
  end

  test 'sort by newest and paginate collections' do
    visit community_path(@community)
    # Sort with newest first
    click_button 'Sort by'
    click_link 'Date (newest first)'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'desc')
    assert_selector 'button', text: 'Date (newest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 10'
    assert_selector 'ul.list-group li:nth-child(2) a', text: 'Nice Collection 09'
    assert_selector 'ul.list-group li:nth-child(9) a', text: 'Fancy Collection 02'
    assert_selector 'ul.list-group li:nth-child(10) a', text: 'Nice Collection 01'
    # The first 'Fancy' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 00'

    click_link 'Next'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'desc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 00'
  end

  test 'sort by ascending alphabetical order and paginate collections' do
    visit community_path(@community)
    # Sort the other way again
    click_button 'Sort by'
    click_link 'Title (A-Z)'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'asc')
    assert_selector 'button', text: 'Title (A-Z)'
    assert_selector 'div', text: '1 - 10 of 11'
    # First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'ul.list-group li:nth-child(2) a', text: 'Fancy Collection 02'
    assert_selector 'ul.list-group li:nth-child(9) a', text: 'Nice Collection 05'
    assert_selector 'ul.list-group li:nth-child(10) a', text: 'Nice Collection 07'
  end

  test 'sort by oldest and paginate collections' do
    visit community_path(@community)
    # Sort with oldest first
    click_button 'Sort by'
    click_link 'Date (oldest first)'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'asc')
    assert_selector 'button', text: 'Date (oldest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'ul.list-group li:nth-child(2) a', text: 'Nice Collection 01'
    assert_selector 'ul.list-group li:nth-child(9) a', text: 'Fancy Collection 08'
    assert_selector 'ul.list-group li:nth-child(10) a', text: 'Nice Collection 09'
    # The Last 'Nice' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 10'
    click_link 'Next'

    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'asc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'ul.list-group li:first-child a', text: 'Fancy Collection 10'
  end

end
