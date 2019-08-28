require 'application_system_test_case'

class CommunitiesTypeaheadTest < ApplicationSystemTestCase

  def before_all
    super
    admin = User.find_by(email: 'administrator@example.com')
    @community = Community.new(title: 'Department of thing', owner_id: admin.id)
                          .save!
    @community2 = Community.new(title: 'Other community', owner_id: admin.id)
                           .save!
    Collection.new(title: 'Articles about thing', owner_id: admin.id, community_id: @community.id)
              .save!
    Collection.new(title: 'Other stuff', owner_id: admin.id, community_id: @community.id)
              .save!
    @collection = Collection.new(title: 'Other stuff things', owner_id: admin.id, community_id: @community2.id)
                            .save!
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
