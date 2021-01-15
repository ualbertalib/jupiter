require 'test_helper'

class SearchSortDirectionFallbackTest < ActionDispatch::IntegrationTest

  test 'search with sort without default sort direction still succeeds' do
    get search_url, params: { sort: 'sort_year' }
    assert_response :success
  end

end
