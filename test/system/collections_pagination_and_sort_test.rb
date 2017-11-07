require 'application_system_test_case'

class CollectionsPaginationAndSortTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Community', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    # For sorting, creation order is 'Fancy Collection 00', 'Nice Collection 01', 'Fancy Collection 02', etc. ...
    (0..25).each do |i|
      Collection.new_locked_ldp_object(title: format("#{['Fancy', 'Nice'][i % 2]} Collection %02i", i), owner: 1,
                                       community_id: @community.id)
                .unlock_and_fetch_ldp_object(&:save!)
    end
  end

  context 'Non-logged in user (or anybody really)' do
    should 'be able to sort and paginate collections' do
      visit community_path(@community)
      assert_selector('div', text: '1 - 25 of 26')
      # Default sort is by title. First 13 say 'Fancy', last 12 say 'Nice'
      # Below: /Fancy Collection 00.*Fancy Collection 02.*<SNIP>.*Nice Collection 21.*Nice Collection 23/
      a_to_z_match = Regexp.new(((0..12).map { |i| format('Fancy Collection %02i', 2 * i) } +
                                 (0..11).map { |i| format('Nice Collection %02i', 2 * i + 1) }).join('.*'))
      assert_match(a_to_z_match, page.text)

      # The last 'Nice' collection should be on next page
      refute_match(/Nice Collection 25/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Nice Collection 25/, page.text)

      # Sort links
      click_button 'Sort by'
      assert_selector 'a', text: 'Name (A-Z)'
      assert_selector 'a', text: 'Name (Z-A)'
      assert_selector 'a', text: 'Date (newest first)'
      assert_selector 'a', text: 'Date (oldest first)'

      # Reverse sort
      click_link 'Name (Z-A)'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'desc')
      assert_selector('div', text: '1 - 25 of 26')
      assert_selector 'button', text: 'Name (Z-A)'
      # Below: /Nice Collection 25.*Nice Collection 23.*<SNIP>.*Fancy Collection 25.*<SNIP>.*Fancy Collection 02/
      z_to_a_match = Regexp.new(((1..12).map { |i| format('Fancy Collection %02i', 2 * i) } +
                                 (0..12).map { |i| format('Nice Collection %02i', 2 * i + 1) }).reverse.join('.*'))
      assert_match(z_to_a_match, page.text)

      # The first 'Fancy' collection should be on next page
      refute_match(/Fancy Collection 00/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'desc',
                                                                                  page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Fancy Collection 00/, page.text)

      # Sort the other way again
      click_button 'Name (Z-A)'
      click_link 'Name (A-Z)'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'title', direction: 'asc')
      assert_selector 'button', text: 'Name (A-Z)'
      assert_selector('div', text: '1 - 25 of 26')
      # Reuse regex from default sort above
      assert_match(a_to_z_match, page.text)

      # Sort with newest first
      click_button 'Name (A-Z)'
      click_link 'Date (newest first)'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                  direction: 'desc')
      assert_selector 'button', text: 'Date (newest first)'
      assert_selector('div', text: '1 - 25 of 26')
      # Below: /Nice Collection 25.*Fancy Collection 24.*<SNIP>.*Fancy Collection 02.*<SNIP>.*Nice Collection 01/
      newest_match = Regexp.new((1..25).map { |i| format("#{['Fancy', 'Nice'][i % 2]} Collection %02i", i) }
                                       .reverse.join('.*'))
      assert_match(newest_match, page.text)
      # The first 'Fancy' collection should be on next page
      refute_match(/Fancy Collection 00/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                  direction: 'desc', page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Fancy Collection 00/, page.text)

      # Sort with oldest first
      click_button 'Date (newest first)'
      click_link 'Date (oldest first)'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                  direction: 'asc')
      assert_selector 'button', text: 'Date (oldest first)'
      assert_selector('div', text: '1 - 25 of 26')
      # Below: /Fancy Collection 00.*Nice Collection 01.*<SNIP>.*Nice Collection 23.*<SNIP>.*Fancy Collection 24/
      newest_match = Regexp.new((0..24).map { |i| format("#{['Fancy', 'Nice'][i % 2]} Collection %02i", i) }
                                       .join('.*'))
      assert_match(newest_match, page.text)
      # The Last 'Nice' collection should be on next page
      refute_match(/Nice Collection 25/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, community_path(@community, sort: 'record_created_at',
                                                                                  direction: 'asc', page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Nice Collection 25/, page.text)
    end
  end

end
