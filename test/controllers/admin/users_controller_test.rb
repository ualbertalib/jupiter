require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    sign_in_as @admin
  end

  test 'should be able to get to admin users index as admin user' do
    get admin_users_url
    assert_response :success
  end

  test 'should be able to get to admin users show as admin user' do
    get admin_user_url(@admin)
    assert_response :success
  end

  test 'should be able to suspend a user' do
    user = users(:regular)

    patch suspend_admin_user_url(user)

    assert_redirected_to admin_user_url(user)
    assert_equal I18n.t('admin.users.show.suspend_flash'), flash[:notice]

    user.reload
    assert user.suspended?
  end

  test 'should be able to unsuspend a user' do
    user = users(:suspended)

    patch unsuspend_admin_user_url(user)

    assert_redirected_to admin_user_url(user)
    assert_equal I18n.t('admin.users.show.unsuspend_flash'), flash[:notice]

    user.reload
    refute user.suspended?
  end

  test 'should be able to grant admin to a user' do
    user = users(:regular)

    patch grant_admin_admin_user_url(user)
    assert_redirected_to admin_user_url(user)
    assert_equal I18n.t('admin.users.show.grant_admin_flash'), flash[:notice]

    user.reload
    assert user.admin?
  end

  test 'should be able to revoke admin to an admin' do
    user = users(:admin_two)

    patch revoke_admin_admin_user_url(user)

    assert_redirected_to admin_user_url(user)
    assert_equal I18n.t('admin.users.show.revoke_admin_flash'), flash[:notice]

    user.reload
    refute user.admin?
  end

  test 'should be able to login as user' do
    user = users(:regular)

    post login_as_user_admin_user_url(user)
    assert_redirected_to root_url
    assert_equal I18n.t('admin.users.show.login_as_user_flash', user: user.name), flash[:notice]

    assert_equal session[:user_id], user.id
    assert_equal session[:admin_id], @admin.id
  end

end
