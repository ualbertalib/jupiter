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
