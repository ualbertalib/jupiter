require 'application_system_test_case'

class CommunitiesPaginationAndSortTest < ApplicationSystemTestCase

  setup do
    # for some runs/seeds (like SEED=1099), stale Communities are left over from other tests.
    # We need to assume the communities created here are the only ones!
    Community.delete_all

    admin = users(:user_admin)
    (0..10).each do |i|
      Community.new(title: format("#{random_title(i)} Community %02i", i), owner_id: admin.id).save!
    end
  end

  # TODO: Slow test
  test 'anybody should be able to sort and paginate communities' do
    # for some runs/seeds (like SEED=1099), stale Communities are left over from other tests. We can't assume the
    # communities created here are the only ones! This test needs to be re-written
    # For sorting, creation order is 'Fancy Community 00', 'Nice Community 01', 'Fancy Community 02', etc. ...
    #
    # Try SEED=8921

    visit communities_path

    assert_selector 'div', text: '1 - 10 of 11'
    # Default sort is by title. First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'li:first-child a', text: 'Fancy Community 00'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Community 02'
    assert_selector 'li:nth-child(9) a', text: 'Nice Community 05'
    assert_selector 'li:last-child a', text: 'Nice Community 07'

    # The last one should be on next page
    refute_selector 'a', text: 'Nice Community 09'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, communities_path(page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Nice Community 09'

    # Sort links
    click_button 'Sort by'
    assert_selector 'a', text: 'Title (A-Z)'
    assert_selector 'a', text: 'Title (Z-A)'
    assert_selector 'a', text: 'Date (newest first)'
    assert_selector 'a', text: 'Date (oldest first)'

    # Reverse sort
    click_link 'Title (Z-A)'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'desc')
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'button', text: 'Title (Z-A)'
    assert_selector 'li:first-child a', text: 'Nice Community 09'
    assert_selector 'li:nth-child(2) a', text: 'Nice Community 07'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Community 04'
    assert_selector 'li:last-child a', text: 'Fancy Community 02'
    # The first 'Fancy' community should be on next page
    refute_selector 'a', text: 'Fancy Community 00'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'desc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Community 00'

    # Sort the other way again
    click_button 'Title (Z-A)'
    click_link 'Title (A-Z)'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'title', direction: 'asc')
    assert_selector 'button', text: 'Title (A-Z)'
    assert_selector 'div', text: '1 - 10 of 11'
    # Default sort is by title. First 6 say 'Fancy', last 4 say 'Nice'
    assert_selector 'li:first-child a', text: 'Fancy Community 00'
    assert_selector 'li:nth-child(2) a', text: 'Fancy Community 02'
    assert_selector 'li:nth-child(9) a', text: 'Nice Community 05'
    assert_selector 'li:last-child a', text: 'Nice Community 07'

    # Sort with newest first
    click_button 'Title (A-Z)'
    click_link 'Date (newest first)'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'desc')
    assert_selector 'button', text: 'Date (newest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Community 10'
    assert_selector 'li:nth-child(2) a', text: 'Nice Community 09'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Community 02'
    assert_selector 'li:last-child a', text: 'Nice Community 01'
    # The first 'Fancy' community should be on next page
    refute_selector 'a', text: 'Fancy Community 00'
    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at',
                                                                      direction: 'desc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Community 00'

    # Sort with oldest first
    click_button 'Date (newest first)'
    click_link 'Date (oldest first)'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at', direction: 'asc')
    assert_selector 'button', text: 'Date (oldest first)'
    assert_selector 'div', text: '1 - 10 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Community 00'
    assert_selector 'li:nth-child(2) a', text: 'Nice Community 01'
    assert_selector 'li:nth-child(9) a', text: 'Fancy Community 08'
    assert_selector 'li:last-child a', text: 'Nice Community 09'
    # The Last 'Fancy' community should be on next page
    refute_selector 'a', text: 'Fancy Community 10'

    click_link 'Next'
    assert_equal URI.parse(current_url).request_uri, communities_path(sort: 'record_created_at',
                                                                      direction: 'asc', page: '2')
    assert_selector 'div', text: '11 - 11 of 11'
    assert_selector 'li:first-child a', text: 'Fancy Community 10'
  end

end
