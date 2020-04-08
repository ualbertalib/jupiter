require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item1 = items(:fancy)
    @item2 = items(:admin)
    @item3 = items(:authenticated_item)
    @item4 = items(:private_item)

    [@item1, @item2, @item3, @item4].each(&:update_solr)
  end

  test 'should get results in alphabetical order when no query present' do
    get search_url, as: :json, params: { search: '' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }
    assert_equal([@item2.id, @item3.id, @item1.id], results)
    assert_not_equal([@item4.id], results)
  end

  test 'should get all results in alphabetical order when no query present when signed in as admin' do
    sign_in_as(users(:admin))
    get search_url, as: :json, params: { search: '' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }
    assert_equal([@item2.id, @item3.id, @item1.id, @item4.id], results)
  end

  test 'should get results in relevance order when a query is present' do
    get search_url, as: :json, params: { search: 'Item' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }

    # TODO: is there a way to set relevance score?
    # Each item has the same relevance score, so just check each item
    # is includes in the json results (otherwise this will be a flakey test)
    assert_includes(results, @item1.id)
    assert_includes(results, @item2.id)
    assert_includes(results, @item3.id)
    assert_not_includes(results, @item4.id)
  end

  test 'should only get results matching query' do
    get search_url, as: :json, params: { search: 'Fancy Item' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }

    assert_includes(results, @item1.id)
    assert_not_includes(results, @item2.id)
    assert_not_includes(results, @item3.id)
    assert_not_includes(results, @item4.id)
  end

  test 'should work when asking for HTML results too' do
    get search_url, params: { search: 'Item' }
    assert_response :success

    [@item1, @item2, @item3].each do |expected_result|
      assert_match(/<a href="\/items\/#{expected_result.id}">/, response.body)
    end
    assert_no_match(/<a href="\/items\/#{@item4.id}">/, response.body)
  end

end
