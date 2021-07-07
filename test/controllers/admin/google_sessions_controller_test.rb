require 'test_helper'

class Admin::GoogleSessionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    sign_in_as users(:user_admin)
  end

  test 'new action should redirect to google oauth url when not given valid code' do
    get new_admin_google_session_url

    assert_response :redirect
    assert_redirected_to %r{\Ahttps://accounts.google.com/o/oauth2/auth}
  end

  test 'new action should retrieve google credentials when given a valid code' do
    VCR.use_cassette('google_fetch_access_token', record: :none) do
      get new_admin_google_session_url, params: {
        code: 'RANDOMCODE'
      }
    end

    assert_response :redirect
    assert_redirected_to new_admin_batch_ingest_url

    follow_redirect!
    assert_response :success
  end

end
