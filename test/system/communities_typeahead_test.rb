require 'application_system_test_case'

class CommunitiesTypeaheadTest < ApplicationSystemTestCase

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Department of thing', owner: 1)
                          .unlock_and_fetch_ldp_object(&:save!)
    @community2 = Community.new_locked_ldp_object(title: 'Other community', owner: 1)
                           .unlock_and_fetch_ldp_object(&:save!)
    Collection.new_locked_ldp_object(title: 'Articles about thing', owner: 1, community_id: @community.id)
              .unlock_and_fetch_ldp_object(&:save!)
    Collection.new_locked_ldp_object(title: 'Other stuff', owner: 1, community_id: @community.id)
              .unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Other stuff things', owner: 1, community_id: @community2.id)
                            .unlock_and_fetch_ldp_object(&:save!)
  end

  context 'Non-logged in user (or anybody really)' do
    should 'be able to typeahead communities and collections' do
      visit communities_path
      # Click to expose input
      find('.select2-container').click

      # Start typing ...
      find('.select2-search input').set('thin')

      # Community search results
      communities = find('.select2-results li:first-child', text: 'Communities')
      communities.assert_selector('li', count: 1)
      communities.assert_selector('li', text: 'Department of thing')
      communities.refute_selector('li', text: 'Other community')

      # Collection search results
      collections = find('.select2-results li:last-child', text: 'Collections')
      collections.assert_selector('li', count: 2)
      collections.assert_selector('li', text: 'Department of thing -- Articles about thing')
      collections.assert_selector('li', text: 'Other community -- Other stuff things')

      # Select a result to visit the page
      collections.find('li', text: 'Other community -- Other stuff things').click
      assert_equal URI.parse(current_url).request_uri, community_collection_path(@community2, @collection)
    end
  end

end
