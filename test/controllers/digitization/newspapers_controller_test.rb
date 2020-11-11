require 'test_helper'

class Digitization::NewspapersControllerTest < ActionDispatch::IntegrationTest

  setup do
    @digitization_newspaper = digitization_newspapers(:la_survivance)
  end

  test 'should show digitization_newspaper' do
    get digitization_newspaper_url(@digitization_newspaper)
    assert_response :success
  end

end
