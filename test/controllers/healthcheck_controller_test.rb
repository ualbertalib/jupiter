require 'test_helper'

class HealthcheckControllerTest < ActionDispatch::IntegrationTest

  test 'should get healthcheck' do
    get healthcheck_url

    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 200, response['code']
    assert_equal 'OK', response['status']
  end

end
