require 'test_helper'

class UserSearchServiceTest < ActiveSupport::TestCase

  setup do
    @regular_user_item = items(:fancy)
    @admin_item = items(:admin)
    @admin_private_item = items(:private_item)

    [@regular_user_item, @admin_item, @admin_private_item].each(&:update_solr)
  end

  test 'should raise ArgumentError when not given correct arguments' do
    assert_raise(ArgumentError) do
      UserSearchService.new
    end
  end

  test 'should raise ArgumentError if base_restriction_key is given with no value' do
    current_user = users(:regular)
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
    current_user = users(:admin)
    params = ActionController::Parameters.new(search: 'Item')

    search = UserSearchService.new(
      current_user: current_user,
      params: params
    )

    assert_instance_of JupiterCore::SolrServices::DeferredFacetedSolrQuery, search.results
    assert_equal search.results.count, 3
  end

  test 'should filter search results by visibility of current_user' do
    current_user = users(:regular)
    params = ActionController::Parameters.new(search: 'Item')

    search = UserSearchService.new(
      current_user: current_user,
      params: params
    )

    assert_equal search.results.count, 2
    assert_not_includes search.results, @admin_private_item
  end

  test 'should limit results by base_restriction_key and value' do
    current_user = users(:regular)
    params = ActionController::Parameters.new(search: 'Item')
    base_restriction_key = Item.solr_exporter_class.solr_name_for(:owner, role: :exact_match)

    search = UserSearchService.new(
      current_user: current_user,
      params: params,
      base_restriction_key: base_restriction_key,
      value: current_user.id
    )

    # Only Fancy item is owned by regular user
    assert_equal search.results.count, 1
    assert_equal search.results.first.id, @regular_user_item.id
  end

  test 'should return search results with highlights' do
    current_user = users(:regular)
    params = ActionController::Parameters.new(search: 'French')
    highlight_field = Item.solr_exporter_class.solr_name_for(:description, role: :search)

    search = UserSearchService.new(
      current_user: current_user,
      params: params,
      highlight_fields: [
        highlight_field
      ]
    )

    # Only Admin item has "French" in its description
    assert_equal search.results.count, 1
    assert_equal search.results.highlights.count, 1
    assert_equal search.results.first.id, @admin_item.id
    assert_match(/<mark>French<\/mark>/, search.results.highlights[@admin_item.id][highlight_field].first)
  end

end
