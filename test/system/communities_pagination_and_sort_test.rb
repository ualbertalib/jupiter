require 'application_system_test_case'

class CommunitiesPaginationAndSortTest < ApplicationSystemTestCase

  setup do
    @default_per_page = 10
    Kaminari.configure do |c|
      @default_per_page = c.default_per_page
      c.default_per_page = 3
    end
  end

  teardown do
    Kaminari.configure { |c| c.default_per_page = @default_per_page }
  end

  test 'anybody should be able to paginate communities' do
    visit communities_path

    assert_selector 'div', text: '1 - 3 of 4'
    assert_selector 'li:first-child a', text: 'Books'
    assert_selector 'li:nth-child(2) a', text: 'Community with no collections'
    assert_selector 'li:last-child a', text: 'Fancy Community'

    # The last one should be on next page
    refute_selector 'a', text: 'Thesis'
    click_link 'Next'

    assert_equal URI.parse(current_url).request_uri, communities_path(page: '2')
    assert_selector 'div', text: '4 - 4 of 4'
    assert_selector 'li:first-child a', text: 'Thesis'
  end

  test 'anybody should be able to sort by title descending and ascending' do
    visit communities_path

    click_button 'Sort by'

    # Reverse sort
    click_link 'Title (Z-A)'

    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'desc')
    assert_selector 'button', text: 'Title (Z-A)'
    assert_selector 'li:first-child a', text: 'Thesis'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Community'
    assert_selector 'li:last-child a', text: 'Community with no collections'

    # Sort the other way again
    click_button 'Title (Z-A)'
    click_link 'Title (A-Z)'

    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'asc')
    assert_selector 'button', text: 'Title (A-Z)'
    assert_selector 'li:first-child a', text: 'Books'
    assert_selector 'li:nth-child(2) a', text: 'Community with no collections'
    assert_selector 'li:last-child a', text: 'Fancy Community'
  end

  test 'anybody should be able to sort by date descending and ascending' do
    visit communities_path

    click_button 'Sort by'

    # Sort with newest first
    click_link 'Date (newest first)'

    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'desc')
    assert_selector 'button', text: 'Date (newest first)'
    assert_selector 'li:first-child a', text: 'Books'
    assert_selector 'li:nth-child(2) a', text: 'Thesis'
    assert_selector 'li:last-child a', text: 'Fancy Community'

    # Sort with oldest first
    click_button 'Date (newest first)'
    click_link 'Date (oldest first)'

    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'asc')
    assert_selector 'button', text: 'Date (oldest first)'
    assert_selector 'li:first-child a', text: 'Community with no collections'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Community'
    assert_selector 'li:last-child a', text: 'Thesis'
  end

end
