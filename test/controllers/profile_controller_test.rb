require 'test_helper'

class ProfileControllerTest < ActionDispatch::IntegrationTest

  test 'should get profile index' do
    sign_in_as(users(:admin))
    get profile_url
    assert_response :success
  end

end
