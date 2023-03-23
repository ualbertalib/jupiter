require 'test_helper'

class UserSearchServiceTest < ActiveSupport::TestCase

  setup do
    @regular_user_item = items(:item_fancy)
    @admin_item = items(:item_admin)
    @admin_private_item = items(:item_private)

    [@regular_user_item, @admin_item, @admin_private_item].each(&:update_solr)
  end

  test 'should raise ArgumentError when not given correct arguments' do
    assert_raise(ArgumentError) do
      UserSearchService.new
    end
  end

  test 'should raise ArgumentError if base_restriction_key is given with no value' do
    current_user = users(:user_regular)
    params = ActionController::Parameters.new(search: 'Item')
    base_restriction_key = Item.solr_exporter_class.solr_name_for(:owner, role: :exact_match)

    assert_raise(ArgumentError) do
      UserSearchService.new(
        current_user: current_user,
        params: params,
        base_restriction_key: base_restriction_key
      )
    end
  end

  test 'should return search results when given correct arguments' do
    current_user = users(:user_admin)
    params = ActionController::Parameters.new(search: 'Item')

    search = UserSearchService.new(
      current_user: current_user,
      params: params
    )

    assert_instance_of JupiterCore::SolrServices::DeferredFacetedSolrQuery, search.results
    assert_equal(3, search.results.count)
  end

  test 'should filter search results by visibility of current_user' do
    current_user = users(:user_regular)
    params = ActionController::Parameters.new(search: 'Item')

    search = UserSearchService.new(
      current_user: current_user,
      params: params
    )

    assert_equal(2, search.results.count)
    assert_not_includes search.results, @admin_private_item
  end

  test 'should limit results by base_restriction_key and value' do
    current_user = users(:user_regular)
    params = ActionController::Parameters.new(search: 'Item')
    base_restriction_key = Item.solr_exporter_class.solr_name_for(:owner, role: :exact_match)

    search = UserSearchService.new(
      current_user: current_user,
      params: params,
      base_restriction_key: base_restriction_key,
      value: current_user.id
    )

    # Only Fancy item is owned by regular user
    assert_equal(1, search.results.count)
    assert_equal search.results.first.id, @regular_user_item.id
  end

  test 'should return search results with highlights' do
    current_user = users(:user_regular)
    params = ActionController::Parameters.new(search: 'French')

    search = UserSearchService.new(
      current_user: current_user,
      params: params,
      fulltext: true
    )

    # Only Admin item has "French" in its description
    assert_equal(1, search.results.count)

    search.results.each_with_fulltext_results do |result, fulltext_hits|
      assert_equal result.id, @admin_item.id
      assert_equal(1, fulltext_hits.count)
      assert_match(
        /<mark>French<\/mark>/,
        fulltext_hits.first.highlight_text
      )
    end
  end

end
