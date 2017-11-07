require 'application_system_test_case'

class CommunitiesPaginationAndSortTest < ApplicationSystemTestCase

  def before_all
    super
    # For sorting, creation order is 'Fancy Community 00', 'Nice Community 01', 'Fancy Community 02', etc. ...
    (0..25).each do |i|
      Community.new_locked_ldp_object(title: format("#{['Fancy', 'Nice'][i % 2]} Community %02i", i), owner: 1)
               .unlock_and_fetch_ldp_object(&:save!)
    end
  end

  context 'Non-logged in user (or anybody really)' do
    should 'be able to sort and paginate communities' do
      visit communities_path
      assert_selector('div', text: '1 - 25 of 26')
      # Default sort is by title. First 13 say 'Fancy', last 12 say 'Nice'
      # Below: /Fancy Community 00.*Fancy Community 02.*<SNIP>.*Nice Community 21.*Nice Community 23/
      a_to_z_match = Regexp.new(((0..12).map { |i| format('Fancy Community %02i', 2 * i) } +
                                 (0..11).map { |i| format('Nice Community %02i', 2 * i + 1) }).join('.*'))
      assert_match(a_to_z_match, page.text)

      # The last 'Nice' community should be on next page
      refute_match(/Nice Community 25/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, communities_path(page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Nice Community 25/, page.text)

      # Sort links
      click_button 'Sort by'
      assert_selector 'a', text: 'Name (A-Z)'
      assert_selector 'a', text: 'Name (Z-A)'
      assert_selector 'a', text: 'Date (newest first)'
      assert_selector 'a', text: 'Date (oldest first)'

      # Reverse sort
      click_link 'Name (Z-A)'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'desc')
      assert_selector('div', text: '1 - 25 of 26')
      assert_selector 'button', text: 'Name (Z-A)'
      # Below: /Nice Community 25.*Nice Community 23.*<SNIP>.*Fancy Community 25.*<SNIP>.*Fancy Community 02/
      z_to_a_match = Regexp.new(((1..12).map { |i| format('Fancy Community %02i', 2 * i) } +
                                 (0..12).map { |i| format('Nice Community %02i', 2 * i + 1) }).reverse.join('.*'))
      assert_match(z_to_a_match, page.text)

      # The first 'Fancy' community should be on next page
      refute_match(/Fancy Community 00/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'desc', page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Fancy Community 00/, page.text)

      # Sort the other way again
      click_button 'Name (Z-A)'
      click_link 'Name (A-Z)'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'asc')
      assert_selector 'button', text: 'Name (A-Z)'
      assert_selector('div', text: '1 - 25 of 26')
      # Reuse regex from default sort above
      assert_match(a_to_z_match, page.text)

      # Sort with newest first
      click_button 'Name (A-Z)'
      click_link 'Date (newest first)'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'desc')
      assert_selector 'button', text: 'Date (newest first)'
      assert_selector('div', text: '1 - 25 of 26')
      # Below: /Nice Community 25.*Fancy Community 24.*<SNIP>.*Fancy Community 02.*<SNIP>.*Nice Community 01/
      newest_match = Regexp.new((1..25).map { |i| format("#{['Fancy', 'Nice'][i % 2]} Community %02i", i) }
                                       .reverse.join('.*'))
      assert_match(newest_match, page.text)
      # The first 'Fancy' community should be on next page
      refute_match(/Fancy Community 00/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at',
                                                                        direction: 'desc', page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Fancy Community 00/, page.text)

      # Sort with oldest first
      click_button 'Date (newest first)'
      click_link 'Date (oldest first)'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'asc')
      assert_selector 'button', text: 'Date (oldest first)'
      assert_selector('div', text: '1 - 25 of 26')
      # Below: /Fancy Community 00.*Nice Community 01.*<SNIP>.*Nice Community 23.*<SNIP>.*Fancy Community 24/
      newest_match = Regexp.new((0..24).map { |i| format("#{['Fancy', 'Nice'][i % 2]} Community %02i", i) }
                                       .join('.*'))
      assert_match(newest_match, page.text)
      # The Last 'Nice' community should be on next page
      refute_match(/Nice Community 25/, page.text)
      click_link 'Next'
      assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at',
                                                                        direction: 'asc', page: '2')
      assert_selector('div', text: '26 - 26 of 26')
      assert_match(/Nice Community 25/, page.text)
    end
  end

end
