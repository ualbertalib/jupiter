require 'test_helper'

class Admin::UserPolicyTest < ActiveSupport::TestCase

  setup do
    @current_user = users(:admin)
    @user = users(:regular)
    @suspended_user = users(:suspended)
    @admin_user = users(:admin_two)
  end

  test 'should not be able to suspend a supended user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).suspend?
  end

  test 'should not be able to suspend yourself' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @current_user]).suspend?
  end

  test 'should not be able to suspend an admin user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).suspend?
  end

  test 'should be able to suspend a regular user' do
    assert Admin::UserPolicy.new(@current_user, [:admin, @user]).suspend?
  end

  test 'should not be able to unsuspend an unsupended user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @user]).unsuspend?
  end

  test 'should be able to unsuspend a regular suspended user' do
    assert Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).unsuspend?
  end

  test 'should not be able to grant admin to a supended user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).grant_admin?
  end

  test 'should not be able to grant admin to yourself' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @current_user]).grant_admin?
  end

  test 'should not be able to grant admin to an admin user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).grant_admin?
  end

  test 'should be able to grant admin to a regular user' do
    assert Admin::UserPolicy.new(@current_user, [:admin, @user]).grant_admin?
  end

  test 'should not be able to revoke admin to a suspended user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).revoke_admin?
  end

  test 'should not be able to revoke admin for yourself' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @current_user]).revoke_admin?
  end

  test 'should not be able to revoke_admin to a non admin user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @user]).revoke_admin?
  end

  test 'should be able to revoke_admin to an admin user' do
    assert Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).revoke_admin?
  end

  test 'should not be able to login as a supended user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).login_as_user?
  end

  test 'should not be able to login as yourself' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @current_user]).login_as_user?
  end

  test 'should not be able to login as an admin user' do
    assert_not Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).login_as_user?
  end

  test 'should be able to login as a regular user' do
    assert Admin::UserPolicy.new(@current_user, [:admin, @user]).login_as_user?
  end

end
