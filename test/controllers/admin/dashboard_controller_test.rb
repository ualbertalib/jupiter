require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest

  test 'should not be able to get to /admin if anon user' do
    assert_raises ActionController::RoutingError do
      get admin_root_url
    end
  end

  test 'should not be able to get to /admin if non admin user' do
    user = users(:user_regular)
    sign_in_as user

    assert_raises ActionController::RoutingError do
      get admin_root_url
    end
  end

  test 'should get to admin dashboard as admin user' do
    admin = users(:user_admin)
    sign_in_as admin

    assert logged_in?

    get admin_root_url
    assert_response :success
  end

end
