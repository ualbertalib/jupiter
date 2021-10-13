require 'test_helper'

class SearchInvalidDateRange < ActionDispatch::IntegrationTest

  test 'search with invalid date range shows alert' do
    sort_year_facet = Item.solr_exporter_class.solr_name_for(:sort_year, role: :range_facet)
    get search_url(ranges: { sort_year_facet => { begin: 2022, end: 2021 } })
    assert_response :success
    assert_equal I18n.t('search.invalid_date_range_flash'), flash[:alert]
  end

end
