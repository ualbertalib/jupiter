require 'application_system_test_case'

class SearchTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new(title: 'Fancy Community', owner_id: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @collections = 2.times.map do |i|
      Collection.new(community_id: @community.id,
                                       title: "Fancy Collection #{i}", owner_id: 1)
                .unlock_and_fetch_ldp_object(&:save!)
    end

    # Half items have 'Fancy' in title, others have 'Nice', distributed between the two collections
    @items = 10.times.map do |i|
      if i < 5
        Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                   owner_id: 1, title: "#{['Fancy', 'Nice'][i % 2]} Item #{i}",
                                   creators: ['Joe Blow'],
                                   created: "19#{50 + i}-11-11",
                                   languages: [CONTROLLED_VOCABULARIES[:language].english],
                                   item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                   publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                   license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                   subject: ['Items'])
            .unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(@community.id, @collections[0].id)
          uo.save!
        end
      else
        Thesis.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                     owner_id: 1, title: "#{['Fancy', 'Nice'][i % 2]} Item #{i}",
                                     dissertant: 'Joe Blow',
                                     language: CONTROLLED_VOCABULARIES[:language].english,
                                     graduation_date: "19#{50 + i}-11-11")
              .unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(@community.id, @collections[1].id)
          uo.save!
        end
      end
    end
    # one more item that is CCID protected
    item = Item.new(visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
                                      owner_id: 1, title: 'Fancy CCID Item',
                                      creators: ['Joe Blow'],
                                      created: '1950-11-11',
                                      languages: [CONTROLLED_VOCABULARIES[:language].english],
                                      item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                      publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                      subject: ['Items'])
               .unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collections[0].id)
      uo.save!
    end
    # needs a file for the download link
    Sidekiq::Testing.inline! do
      File.open(Rails.root + 'app/assets/images/era-logo.png', 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end
    @items << item
    # 10 more items. these are private (some 'Fancy' some 'Nice')
    @items += 10.times.map do |i|
      if i < 5
        Item.new(visibility: JupiterCore::VISIBILITY_PRIVATE,
                                   owner_id: 1, title: "#{['Fancy', 'Nice'][i % 2]} Private Item #{i + 10}",
                                   creators: ['Joe Blow'],
                                   created: "19#{70 + i}-11-11",
                                   languages: [CONTROLLED_VOCABULARIES[:language].english],
                                   item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                   publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                   license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                   subject: ['Items'])
            .unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(@community.id, @collections[0].id)
          uo.save!
        end
      else
        Thesis.new(visibility: JupiterCore::VISIBILITY_PRIVATE,
                                     owner_id: 1, title: "#{['Fancy', 'Nice'][i % 2]} Private Item #{i + 10}",
                                     dissertant: 'Joe Blow',
                                     language: CONTROLLED_VOCABULARIES[:language].english,
                                     graduation_date: "19#{70 + i}-11-11")
              .unlock_and_fetch_ldp_object do |uo|
          uo.add_to_path(@community.id, @collections[1].id)
          uo.save!
        end
      end
    end

    # Create extra items/collections/communities to test 'show more'
    10.times do |i|
      community = Community.new(title: "Extra Community #{i}", owner_id: 1)
                           .unlock_and_fetch_ldp_object(&:save!)
      collection = Collection.new(community_id: community.id,
                                                    title: "Extra Collection #{i}", owner_id: 1)
                             .unlock_and_fetch_ldp_object(&:save!)
      Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                                 owner_id: 1, title: "Extra Item #{i}",
                                 creators: ['Joe Blow'],
                                 created: "19#{90 + i}-11-11",
                                 languages: [CONTROLLED_VOCABULARIES[:language].english],
                                 item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                                 publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
                                 license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                                 subject: ['Items'])
          .unlock_and_fetch_ldp_object do |uo|
        uo.add_to_path(community.id, collection.id)
        uo.save!
      end
    end
  end

  test 'anybody should be able to filter the public items' do
    visit root_path
    fill_in name: 'search', with: 'Fancy'
    click_button 'Search'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy')
    # Tabs
    assert_selector 'a.nav-link.active', text: 'Items (6)'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link', text: 'Communities'

    # Facets and counts
    refute_selector 'div.card-header', text: 'Visibility'
    refute_selector 'li a', text: /5\nPublic/
    refute_selector 'li a', text: /1\nAuthenticated/
    # Should not be a facet for 'private'
    refute_selector 'li a', text: /Private/
    # TODO: The 'Member of paths' text will likely change
    assert_selector 'div.card-header', text: 'Collections'
    assert_selector 'li a', text: /6\nFancy Community/
    assert_selector 'li a', text: /4\nFancy Community\/Fancy Collection 0/
    assert_selector 'li a', text: /2\nFancy Community\/Fancy Collection 1/
    assert_selector 'div.card-header', text: I18n.t('facets.sort_year')
    sort_year_facet =Item.solr_exporter_class.solr_name_for(:sort_year, role: :range_facet)
    assert_selector "#ranges_#{sort_year_facet}_begin"
    assert_selector "#ranges_#{sort_year_facet}_end"
    assert_selector 'input.btn'

    # Exactly 6 items shown
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 6
    assert_selector 'a', text: 'Fancy Item 0'
    assert_selector 'a', text: 'Fancy Item 2'
    assert_selector 'a', text: 'Fancy Item 4'
    assert_selector 'a', text: 'Fancy Item 6'
    assert_selector 'a', text: 'Fancy Item 8'
    assert_selector 'a', text: 'Fancy CCID Item'

    # Should not show CCID download
    within '.list-group-item', text: 'Fancy CCID Item' do
      refute_selector 'a', text: 'Download'
    end

    # A checkbox for the facet should be unchecked, and link should turn on facet
    within 'div.jupiter-filters a', text: 'Fancy Collection 1' do
      assert_selector 'i.fa-square-o', count: 1
    end

    # Click on facet
    click_link 'Fancy Collection 1'

    path = "#{@community.id}/#{@collections[1].id}"
    facet_path = search_path(search: 'Fancy', facets: { member_of_paths_dpsim: [path] })
    assert_equal URI.parse(current_url).request_uri, facet_path

    # Tab counts should only change for this tab
    assert_selector 'a.nav-link.active', text: 'Items (2)'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link', text: 'Communities'

    # Some facets are now gone, some with changed counts
    refute_selector 'div.card-header', text: 'Visibility'
    refute_selector 'li a', text: '2 Public'
    assert_selector 'div.card-header', text: 'Collections'
    assert_selector 'li a', text: /2\nFancy Community/
    assert_selector 'li a', text: 'Fancy Community/Fancy Collection 0', count: 0
    assert_selector 'li a', text: /2\nFancy Community\/Fancy Collection 1/

    # A checkbox for the selected facet should be checked, and link should turn off facet
    within 'div.jupiter-filters a', text: 'Fancy Collection 1' do
      assert_selector 'i.fa-check-square-o', count: 1
    end

    # 2 items shown, 3 not shown
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 2
    assert_selector 'a', text: 'Fancy Item 6'
    assert_selector 'a', text: 'Fancy Item 8'
    assert_selector 'a', text: 'Fancy Item 0', count: 0
    assert_selector 'a', text: 'Fancy Item 2', count: 0
    assert_selector 'a', text: 'Fancy Item 4', count: 0

    # A badge should be displayed for the enabled facet as a link that turns off facet
    badges = find('div.jupiter-facet-badges')
    badge = badges.find_link('a', text: 'Fancy Collection 1', href: search_path(search: 'Fancy'))
    badge.assert_selector 'span.badge', text: 'Fancy Collection 1'
  end

  test 'anybody should be able to view community/collection hits via tabs' do
    visit root_path
    fill_in name: 'search', with: 'Fancy'
    click_button 'Search'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy')

    # Tabs
    assert_selector 'a.nav-link.active', text: 'Items (6)'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link', text: 'Communities'

    # No community/collection results initially shown
    assert_selector 'div.jupiter-results-list h3 a', text: 'Item', count: 6
    assert_selector 'div.jupiter-results-list a', text: 'Community', count: 0
    assert_selector 'div.jupiter-results-list a', text: 'Collection', count: 0

    # Visit community tab
    click_link 'Communities'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy', tab: 'community')
    assert_selector 'a.nav-link', text: 'Items'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link.active', text: 'Communities (1)'
    # Only community hits shown
    assert_selector 'div.jupiter-results-list h3 a', text: 'Item', count: 0
    assert_selector 'div.jupiter-results-list a', text: 'Community', count: 1
    assert_selector 'div.jupiter-results-list a', text: 'Collection', count: 0

    # Visit collection tab
    within('.nav-tabs') do
      click_link 'Collections'
    end
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy', tab: 'collection')
    assert_selector 'a.nav-link', text: 'Items'
    assert_selector 'a.nav-link.active', text: 'Collections (2)'
    assert_selector 'a.nav-link', text: 'Communities'
    # Only collection hits shown
    assert_selector 'div.jupiter-results-list h3 a', text: 'Item', count: 0
    assert_selector 'div.jupiter-results-list a', text: 'Community', count: 0
    assert_selector 'div.jupiter-results-list a', text: 'Collection', count: 2
  end

  test 'anybody should only see some facet results by default, with a "show more" button' do
    skip 'This test continues to flap on CI that should be investigated ASAP' if ENV['TRAVIS']

    visit root_path
    fill_in name: 'search', with: 'Extra'
    click_button 'Search'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Extra')

    # Facets and counts. 20 should match, expect only 6 to be shown
    assert_selector 'div.card-header', text: 'Collections'
    # Note: collection facets also include community name
    assert_selector 'li a', text: /Extra Community/, count: 6

    # Should be a 'Show more' button to see the rest
    assert_selector 'a[aria-controls="member_of_paths_dpsim_hidden"]', count: 1

    click_link 'Show 4 more', href: '#member_of_paths_dpsim_hidden'

    # Now 20 collections/communities should be shown
    assert_selector 'li a', text: /Extra Community/, count: 10

    # Should be a 'Hide' button now
    assert_selector 'a[aria-controls="member_of_paths_dpsim_hidden"]', count: 1

    click_link 'Hide last 4', href: '#member_of_paths_dpsim_hidden'

    # Again, only 6 collections/communities should be shown
    assert_selector 'li a', text: /Extra Community/, count: 6
  end

  test 'anybody should be able to sort results' do
    skip 'This test continues to flap on CI that should be investigated ASAP' if ENV['TRAVIS']

    visit root_path
    fill_in name: 'search', with: 'Fancy'
    click_button 'Search'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy')

    # Default sort is by relevance
    # TODO this test has flapped in the past because the score of each document is equal
    # TODO could go through this section and add the Fancy CCID Item, regex allows tests to pass without this change
    assert_match(/Fancy Item 0.*Fancy Item 2.*Fancy Item 4.*Fancy Item 6.*Fancy Item 8/m, page.text)

    # Sort sort links
    click_button 'Sort by'
    assert_selector 'a', text: 'Title (A-Z)'
    assert_selector 'a', text: 'Title (Z-A)'
    assert_selector 'a', text: 'Date (newest first)'
    assert_selector 'a', text: 'Date (oldest first)'
    assert_selector 'a', text: 'Relevance'

    # Reverse sort
    click_link 'Title (Z-A)'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy', sort: 'title', direction: 'desc')
    assert_selector 'button', text: 'Title (Z-A)'
    assert_match(/Fancy Item 8.*Fancy Item 6.*Fancy Item 4.*Fancy Item 2.*Fancy Item 0/m, page.text)

    # Sort the other way again
    click_button 'Title (Z-A)'
    click_link 'Title (A-Z)'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy', sort: 'title', direction: 'asc')
    assert_selector 'button', text: 'Title (A-Z)'
    assert_match(/Fancy Item 0.*Fancy Item 2.*Fancy Item 4.*Fancy Item 6.*Fancy Item 8/m, page.text)

    # Sort with newest first
    click_button 'Title (A-Z)'
    click_link 'Date (newest first)'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy',
                                                                 sort: 'sort_year', direction: 'desc')
    assert_selector 'button', text: 'Date (newest first)'
    assert_match(/Fancy Item 8.*Fancy Item 6.*Fancy Item 4.*Fancy Item 2.*Fancy Item 0/m, page.text)

    # Sort with oldest first
    click_button 'Date (newest first)'
    click_link 'Date (oldest first)'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy',
                                                                 sort: 'sort_year', direction: 'asc')
    assert_selector 'button', text: 'Date (oldest first)'
    assert_match(/Fancy Item 0.*Fancy Item 2.*Fancy Item 4.*Fancy Item 6.*Fancy Item 8/m, page.text)
  end

  # TODO: Slow Test, consistently around ~8-9 seconds
  test 'admin should be able to filter the public and private items' do
    admin = users(:admin)
    login_user(admin)

    # Search box should be on any page we happen to be on
    fill_in name: 'search', with: 'Fancy'
    click_button 'Search'
    assert_equal URI.parse(current_url).request_uri, search_path(search: 'Fancy')

    # Tabs
    assert_selector 'a.nav-link.active', text: 'Items (11)'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link', text: 'Communities'

    # Facets and counts
    assert_selector 'div.card-header', text: 'Visibility'
    assert_selector 'li a', text: /5\nPublic/
    assert_selector 'li a', text: /1\nAuthenticated/

    # Should be a facet for 'private'
    assert_selector 'li a', text: /5\nPrivate/

    # TODO: The 'Member of paths' text will likely change
    assert_selector 'div.card-header', text: 'Collections'
    assert_selector 'li a', text: /11\nFancy Community/
    assert_selector 'li a', text: /7\nFancy Community\/Fancy Collection 0/
    assert_selector 'li a', text: /4\nFancy Community\/Fancy Collection 1/

    # Exactly 10 items shown
    assert_selector 'div.jupiter-results-list li.list-group-item', count: 10
    assert_selector 'a', text: 'Fancy Item 0'
    assert_selector 'a', text: 'Fancy Item 2'
    assert_selector 'a', text: 'Fancy Item 4'
    assert_selector 'a', text: 'Fancy Item 6'
    assert_selector 'a', text: 'Fancy Item 8'
    assert_selector 'a', text: 'Fancy CCID Item'
    assert_selector 'a', text: 'Fancy Private Item 10'
    assert_selector 'a', text: 'Fancy Private Item 12'
    assert_selector 'a', text: 'Fancy Private Item 14'
    assert_selector 'a', text: 'Fancy Private Item 16'

    # Should see the download link for CCID item
    within '.list-group-item', text: 'Fancy CCID Item' do
      assert_selector 'a', text: 'Download'
      assert_link href: /download/
      assert_no_link href: /active_storage/
    end

    # A checkbox for the facet should be unchecked, and link should turn on facet
    within 'div.jupiter-filters a', text: 'Fancy Collection 1' do
      assert_selector 'i.fa-square-o', count: 1
    end

    # Click on facet
    click_link 'Fancy Collection 1'

    path = "#{@community.id}/#{@collections[1].id}"
    facet_path = search_path(search: 'Fancy', facets: { member_of_paths_dpsim: [path] })
    assert_equal URI.parse(current_url).request_uri, facet_path

    # Tab counts should only change for this tab
    assert_selector 'a.nav-link.active', text: 'Items (4)'
    assert_selector 'a.nav-link', text: 'Collections'
    assert_selector 'a.nav-link', text: 'Communities'

    # Some facets are now gone, some with changed counts
    assert_selector 'div.card-header', text: 'Visibility'
    assert_selector 'li a', text: /2\nPublic/
    assert_selector 'div.card-header', text: 'Collections'
    assert_selector 'li a', text: /4\nFancy Community/
    assert_selector 'li a', text: 'Fancy Community/Fancy Collection 0', count: 0
    assert_selector 'li a', text: /4\nFancy Community\/Fancy Collection 1/

    # A checkbox for the selected facet should be checked, and link should turn off facet
    within 'div.jupiter-filters a', text: 'Fancy Collection 1' do
      assert_selector 'i.fa-check-square-o', count: 1
    end

    # 2 items shown, 3 not shown
    assert_selector 'a', text: 'Fancy Item 6'
    assert_selector 'a', text: 'Fancy Item 8'
    assert_selector 'a', text: 'Fancy Item 0', count: 0
    assert_selector 'a', text: 'Fancy Item 2', count: 0
    assert_selector 'a', text: 'Fancy Item 4', count: 0

    # A badge should be displayed for the enabled facet as a link that turns off facet
    badges = find('div.jupiter-facet-badges')
    badge = badges.find_link('a', text: 'Fancy Collection 1', href: search_path(search: 'Fancy'))
    badge.assert_selector 'span.badge', text: 'Fancy Collection 1'
  end

end
