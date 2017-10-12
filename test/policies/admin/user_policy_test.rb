require 'test_helper'

class Admin::UserPolicyTest < ActiveSupport::TestCase

  setup do
    @current_user = users(:admin)
    @user = users(:regular_user)
    @suspended_user = users(:suspended_user)
    @admin_user = users(:admin_user)
  end

  context '#suspend?' do
    should 'not be able to suspend a supended user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).suspend?
    end

    should 'not be able to suspend yourself' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @current_user]).suspend?
    end

    should 'not be able to suspend an admin user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).suspend?
    end

    should 'be able to suspend a regular user' do
      assert Admin::UserPolicy.new(@current_user, [:admin, @user]).suspend?
    end
  end

  context '#unsuspend?' do
    should 'not be able to unsuspend an unsupended user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @user]).unsuspend?
    end

    should 'be able to unsuspend a regular suspended user' do
      assert Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).unsuspend?
    end
  end

  context '#grant_admin?' do
    should 'not be able to grant admin to a supended user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).grant_admin?
    end

    should 'not be able to grant admin to yourself' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @current_user]).grant_admin?
    end

    should 'not be able to grant admin to an admin user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).grant_admin?
    end

    should 'be able to grant admin to a regular user' do
      assert Admin::UserPolicy.new(@current_user, [:admin, @user]).grant_admin?
    end
  end

  context '#revoke_admin?' do
    should 'not be able to revoke admin to a suspended user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).revoke_admin?
    end

    should 'not be able to revoke admin for yourself' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @current_user]).revoke_admin?
    end

    should 'not be able to revoke_admin to a non admin user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @user]).revoke_admin?
    end

    should 'be able to revoke_admin to an admin user' do
      assert Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).revoke_admin?
    end
  end

  context '#impersonate?' do
    should 'not be able to impersonate a supended user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @suspended_user]).impersonate?
    end

    should 'not be able to impersonate yourself' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @current_user]).impersonate?
    end

    should 'not be able to impersonate an admin user' do
      refute Admin::UserPolicy.new(@current_user, [:admin, @admin_user]).impersonate?
    end

    should 'be able to impersonate a regular user' do
      assert Admin::UserPolicy.new(@current_user, [:admin, @user]).impersonate?
    end
  end

end
