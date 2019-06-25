require 'test_helper'

class RobotsControllerTest < ActionDispatch::IntegrationTest

  test 'should get robots.txt' do
    get '/robots.txt'
    assert_response :success
  end

end
