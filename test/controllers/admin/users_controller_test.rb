require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest

  context '#index' do
    should 'be able to get to admin users index as admin user' do
      admin = users(:admin)
      sign_in_as admin

      get admin_users_url
      assert_response :success
    end
  end

  context '#show' do
    should 'be able to get to admin users show as admin user' do
      admin = users(:admin)
      sign_in_as admin

      get admin_user_url(admin)
      assert_response :success
    end
  end

  context '#suspend' do
    should 'be able to suspend a user' do
      user = users(:user)
      admin = users(:admin)
      sign_in_as admin

      refute user.suspended?
      patch suspend_admin_user_url(user)

      assert_redirected_to admin_user_url(user)
      assert_equal I18n.t('admin.users.show.suspend_flash'), flash[:notice]

      user.reload
      assert user.suspended?
    end
  end

  context '#unsuspend' do
    should 'be able to unsuspend a user' do
      user = users(:user)
      admin = users(:admin)

      sign_in_as admin

      user.suspended = true
      user.save

      assert user.suspended?

      patch unsuspend_admin_user_url(user)

      assert_redirected_to admin_user_url(user)
      assert_equal I18n.t('admin.users.show.unsuspend_flash'), flash[:notice]

      user.reload
      refute user.suspended?
    end
  end

  context '#grant_admin' do
    should 'be able to grant admin to a user' do
      user = users(:user)
      admin = users(:admin)

      sign_in_as admin

      refute user.admin?

      patch grant_admin_admin_user_url(user)
      assert_redirected_to admin_user_url(user)
      assert_equal I18n.t('admin.users.show.grant_admin_flash'), flash[:notice]

      user.reload
      assert user.admin?
    end
  end

  context '#revoke_admin' do
    should 'be able to revoke admin to an admin' do
      user = users(:user)
      admin = users(:admin)

      sign_in_as admin

      user.admin = true
      user.save

      assert user.admin?

      patch revoke_admin_admin_user_url(user)

      assert_redirected_to admin_user_url(user)
      assert_equal I18n.t('admin.users.show.revoke_admin_flash'), flash[:notice]

      user.reload
      refute user.admin?
    end
  end

  context '#impersonate' do
    should 'be able to impersonate another user' do
      user = users(:user)
      admin = users(:admin)

      sign_in_as admin

      post impersonate_admin_user_url(user)
      assert_redirected_to root_url
      assert_equal I18n.t('admin.users.show.impersonate_flash', user: user.name), flash[:notice]

      assert_equal session[:user_id], user.id
      assert_equal session[:impersonator_id], admin.id
    end
  end

end
