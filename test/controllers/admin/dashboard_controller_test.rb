require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest

  should 'not be able to get to /admin if anon user' do
    assert_raises ActionController::RoutingError do
      get admin_root_url
    end
  end

  should 'not be able to get to /admin if non admin user' do
    user = users(:regular)
    sign_in_as user

    assert_raises ActionController::RoutingError do
      get admin_root_url
    end
  end

  should 'get to admin dashboard as admin user' do
    admin = users(:admin)
    sign_in_as admin

    assert logged_in?

    get admin_root_url
    assert_response :success
  end

end
