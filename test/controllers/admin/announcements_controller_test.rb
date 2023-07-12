require 'test_helper'

class Admin::AnnouncementsControllerTest < ActionDispatch::IntegrationTest

  test 'index' do
    sign_in_as(users(:user_admin))
    get admin_announcements_url

    assert_response :success
  end

  test 'create' do
    sign_in_as(users(:user_admin))
    assert_difference('Announcement.current.count') do
      post admin_announcements_url, params: { announcement: { message: 'Some message' } }
    end
    assert_redirected_to admin_announcements_url
  end

  test 'destroy' do
    sign_in_as(users(:user_admin))
    assert_difference('Announcement.past.count') do
      delete admin_announcement_url(announcements(:announcement_current))
    end
    assert_redirected_to admin_announcements_url
    assert_not_includes Announcement.current, announcements(:announcement_current)
  end

end
