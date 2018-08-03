require 'application_system_test_case'

class CollectionsPaginationAndSortTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    # For sorting, creation order is 'Fancy Collection 00', 'Nice Collection 01', 'Fancy Collection 02', etc. ...
    (0..10).each do |i|
      Collection.new_locked_ldp_object(title: format("#{['Fancy', 'Nice'][i % 2]} Collection %02i", i), owner: 1,
                                       community_id: @community.id)
                .unlock_and_fetch_ldp_object(&:save!)
    end
  end

  test 'anybody should be able to sort and paginate collections' do
    skip 'The rest of this test continues to flap on CI for unknown reasons that should be investigated ASAP'
    visit community_path(@community)
    assert_selector 'div', text: '1 - 10 of 11'
    # Default sort is by title. First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Collection 02'
    assert_selector 'li:nth-child(9) a', text: 'Nice Collection 05'
    # Would like to use 'last-child' here, but for some reason it's not working
    assert_selector 'li:nth-child(10) a', text: 'Nice Collection 07'

    # The last one should be on next page
    refute_selector 'a', text: 'Nice Collection 09'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Nice Collection 09'

    # Sort links
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
    assert_selector 'li:first-child a', text: 'Nice Collection 09'
    assert_selector 'li:nth-child(2) a', text: 'Nice Collection 07'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Collection 04'
    assert_selector 'li:nth-child(10) a', text: 'Fancy Collection 02'

    # The first 'Fancy' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 00'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'desc',
                                                                                page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Collection 00'

    # Sort the other way again
    click_button 'Title (Z-A)'
    click_link 'Title (A-Z)'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'asc')
    assert_selector 'button', text: 'Title (A-Z)'
    assert_selector 'div', text: '1 - 10 of 11'
    # First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Collection 02'
    assert_selector 'li:nth-child(9) a', text: 'Nice Collection 05'
    assert_selector 'li:nth-child(10) a', text: 'Nice Collection 07'

    # Sort with newest first
    click_button 'Title (A-Z)'
    click_link 'Date (newest first)'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'desc')
    assert_selector 'button', text: 'Date (newest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Collection 10'
    assert_selector 'li:nth-child(2) a', text: 'Nice Collection 09'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Collection 02'
    assert_selector 'li:nth-child(10) a', text: 'Nice Collection 01'
    # The first 'Fancy' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 00'

    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'desc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Collection 00'

    # Sort with oldest first
    click_button 'Date (newest first)'
    click_link 'Date (oldest first)'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'asc')
    assert_selector 'button', text: 'Date (oldest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Collection 00'
    assert_selector 'li:nth-child(2) a', text: 'Nice Collection 01'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Collection 08'
    assert_selector 'li:nth-child(10) a', text: 'Nice Collection 09'
    # The Last 'Nice' collection should be on next page
    refute_selector 'a', text: 'Fancy Collection 10'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                direction: 'asc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Collection 10'
  end

end
