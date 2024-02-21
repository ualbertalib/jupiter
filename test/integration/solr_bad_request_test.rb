require 'test_helper'

class SolrBadRequestTest < ActionDispatch::IntegrationTest

  test 'request in which solr gives 400 gives a proper response' do
    # Special characters can cause solr to give a 400 error, so let's test that we are handling that properly
    get search_url, params: {
      facets: { all_subjects_sim: ["\"\\'Bacteriocins"] }
    }

    assert_response :bad_request
  end

end
