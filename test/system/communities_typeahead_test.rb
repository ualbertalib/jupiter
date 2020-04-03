require 'application_system_test_case'

class CommunitiesTypeaheadTest < ApplicationSystemTestCase

  setup do
    admin = users(:admin)
    @community = Community.create!(title: 'Department of thing', owner_id: admin.id)
    @community2 = Community.create!(title: 'Other community', owner_id: admin.id)
    Collection.create!(title: 'Articles about thing', owner_id: admin.id, community_id: @community.id)
    Collection.create!(title: 'Other stuff', owner_id: admin.id, community_id: @community.id)
    @collection = Collection.create!(title: 'Other stuff things', owner_id: admin.id, community_id: @community2.id)
  end

  test 'anybody should be able to typeahead communities and collections' do
    visit communities_path
    # Start typing ...
    fill_in(id: 'search_bar', with: 'thin')

    # Typeahead results
    assert_selector('.easy-autocomplete-container li', count: 3) # total results

    # Has sub headings
    assert_selector('.easy-autocomplete-container .eac-category', text: 'Communities')
    assert_selector('.easy-autocomplete-container .eac-category', text: 'Collections')

    assert_selector('.easy-autocomplete-container li', text: 'Department of thing')
    assert_selector('.easy-autocomplete-container li', text: 'Department of thing -- Articles about thing')
    assert_selector('.easy-autocomplete-container li', text: 'Other community -- Other stuff things')

    # Select a result to visit the page
    find('.easy-autocomplete-container li', text: 'Other community -- Other stuff things').click
    assert_current_path(community_collection_path(@community2, @collection))
  end

end
