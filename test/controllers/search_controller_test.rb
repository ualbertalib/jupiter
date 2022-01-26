require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item1 = items(:item_fancy)
    @item2 = items(:item_admin)
    @item3 = items(:item_authenticated)
    @item4 = items(:item_private)

    [@item1, @item2, @item3, @item4].each(&:update_solr)
  end

  test 'should get results in alphabetical order when no query present' do
    get search_url, as: :json, params: { search: '' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }
    assert_equal([@item3.id, @item2.id, @item1.id], results)
    assert_not_equal([@item4.id], results)
  end

  test 'should get all results in alphabetical order when no query present when signed in as admin' do
    sign_in_as(users(:user_admin))
    get search_url, as: :json, params: { search: '' }
    assert_response :success
    results = JSON.parse(response.body).map { |result| result['id'] }
    assert_equal([@item3.id, @item2.id, @item1.id, @item4.id], results)
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

  test 'should NOT render highlights on search result page by default' do
    get search_url, params: { search: 'French' }
    assert_response :success

    assert_no_match(/<mark>French<\/mark>/, response.body)
  end

  test 'should render highlights on search result page when feature flag is on' do
    Flipper.enable(:fulltext_search)

    get search_url, params: { search: 'French' }
    assert_response :success

    assert_match(/<mark>French<\/mark>/, response.body)

    Flipper.disable(:fulltext_search)
  end

  test 'search with invalid date range shows alert' do
    sort_year_facet = Item.solr_exporter_class.solr_name_for(:sort_year, role: :range_facet)
    get search_url(ranges: { sort_year_facet => { begin: 2022, end: 2021 } })
    assert_response :success
    assert_equal I18n.t('search.invalid_date_range_flash'), flash[:alert]
  end

end
