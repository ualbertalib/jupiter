require 'test_helper'

class Digitization::MapsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @digitization_map = digitization_maps(:map)
  end

  test 'should show digitization_map' do
    get digitization_map_url(@digitization_map)

    assert_response :success
  end

end
