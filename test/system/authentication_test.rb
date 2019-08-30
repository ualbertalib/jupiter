require 'application_system_test_case'

class AuthenticationTest < ApplicationSystemTestCase

  JOHNDOE_AUTH_HASH = OmniAuth::AuthHash.new(
    provider: 'saml',
    uid: 'johndoe',
    info: {
      email: 'johndoe@ualberta.ca',
      name: 'John Doe'
    }
  )

  test 'should log in and log out work with correct credentials' do
    visit root_url

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] = JOHNDOE_AUTH_HASH

    click_on I18n.t('application.navbar.links.login')

    assert_text I18n.t('login.success')

    assert_text 'John Doe'

    click_link 'John Doe' # opens user dropdown which has the logout link

    click_link I18n.t('application.navbar.links.logout')

    assert_text I18n.t('sessions.destroy.signed_out')
    assert_selector 'a', text: I18n.t('application.navbar.links.login')
  end

  test 'should not log in and log out with bad credentials' do
    visit root_url

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] = :invalid_credentials

    click_on I18n.t('application.navbar.links.login')

    assert_text I18n.t('login.error')

    assert_selector 'a', text: I18n.t('application.navbar.links.login')
  end

  test 'should get redirected to homepage then back to a protected page, if user is authorized' do
    visit profile_url

    assert_current_path(root_path)
    assert_text I18n.t('authorization.user_not_authorized_try_logging_in')

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] = JOHNDOE_AUTH_HASH

    click_link I18n.t('application.navbar.links.login')

    assert_text I18n.t('login.success')

    assert_current_path(profile_path)
    assert_text I18n.t('admin.users.created')
  end

  test 'should get redirected to homepage then back to homepage again with error, if user is unauthorized' do
    draft_item = draft_items(:completed_describe_item_step)
    draft_item.save
    visit item_draft_path(item_id: draft_item.id, id: :describe_item)

    assert_text I18n.t('authorization.user_not_authorized_try_logging_in')

    assert_current_path(root_path)
    assert_selector 'h2', text: I18n.t('welcome.index.welcome_lead')

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] = JOHNDOE_AUTH_HASH

    click_link I18n.t('application.navbar.links.login')

    assert_text I18n.t('authorization.user_not_authorized')

    assert_current_path(root_path)
    assert_selector 'h2', text: I18n.t('welcome.index.welcome_lead')
  end

  test 'should after login should be redirected back to previous page user was on' do
    # Go to browse page before logging in
    visit communities_path
    assert_selector 'h1', text: I18n.t('communities.index.header')

    Rails.application.env_config['omniauth.auth'] =
      OmniAuth.config.mock_auth[:saml] = JOHNDOE_AUTH_HASH

    click_link I18n.t('application.navbar.links.login')

    assert_text I18n.t('login.success')

    # Still on browse page
    assert_current_path(communities_path)
    assert_selector 'h1', text: I18n.t('communities.index.header')
  end

end
