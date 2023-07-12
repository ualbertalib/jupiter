require 'test_helper'

class SolrBadRequestTest < ActionDispatch::IntegrationTest

  test 'request in which solr gives 400 gives a proper response' do
    get search_url, params: { facets: { all_subjects_sim: ['Antimicrobial', '"blown-pack"'] } }

    assert_response :bad_request

    get search_url, params: { facets: { all_subjects_sim: ['"A Most Extraordinary Case"'] } }

    assert_response :bad_request

    get search_url, params: { facets: { all_subjects_sim: ['"291" (Gallery)'],
                                        departments_sim: ['Department of Art and Design'],
                                        item_type_with_status_sim: ['thesis'],
                                        member_of_paths_dpsim: ['db9a4e71-f809-4385-a274-048f28eb6814'] } }

    assert_response :bad_request

    get search_url, params: { direction: 'asc',
                              facets: { all_subjects_sim: ['Meat spoilage', "\"\\'Bacteriocins", '"blown-pack"'] },
                              sort: 'title' }

    assert_response :bad_request
  end

end
