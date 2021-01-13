require 'test_helper'

class BadSolrRequestTest < ActionDispatch::IntegrationTest

  test 'request in which solr gives 400 gives a proper response' do
    get "#{root_path}/search?facets[all_subjects_sim][]=Antimicrobial&facets[all_subjects_sim][]=%22blown-pack%22"
    assert_response :bad_request
    get "#{root_path}/search?facets[all_subjects_sim][]=%22A+Most+Extraordinary+Case%22"
    assert_response :bad_request
    get "#{root_path}/search?facets[all_subjects_sim][]=%22291%22+%28Gallery%29&facets[departments_sim][]=Department+"\
    'of+Art+and+Design&facets[item_type_with_status_sim][]=thesis&facets[member_of_paths_dpsim][]=d'\
    'b9a4e71-f809-4385-a274-048f28eb6814'
    assert_response :bad_request
    get "#{root_path}/search?direction=asc&facets[all_subjects_sim][]=Meat+spoilage&facets[all_subjects_sim][]="\
    'Bacteriocins&facets[all_subjects_sim][]=%22blown-pack%22&sort=title'
    assert_response :bad_request
    get "#{root_path}/search?facets[all_contributors_sim][]=Ho%2C+Linda&facets[all_subjects_sim][]=Meat+spoilage&"\
    'facets[all_subjects_sim][]=%22blown-pack%22&facets[member_of_paths_dpsim][]=db9a4e71-f809-4385-a274-048f28eb6814'\
    '%2Ff42f3da6-00c3-4581-b785-63725c33c7ce'
    assert_response :bad_request
  end

end
