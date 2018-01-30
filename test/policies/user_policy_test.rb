require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  context 'admin user' do
    should 'have proper authorization over other users' do
      current_user = users(:admin)
      users_profile = users(:regular)

      assert UserPolicy.new(current_user, users_profile).index?

      refute UserPolicy.new(current_user, users_profile).create?
      refute UserPolicy.new(current_user, users_profile).new?

      assert UserPolicy.new(current_user, users_profile).show?
      assert UserPolicy.new(current_user, users_profile).edit?
      assert UserPolicy.new(current_user, users_profile).update?
      assert UserPolicy.new(current_user, users_profile).destroy?
    end
  end

  context 'regular user' do
    should 'allow access to yourself' do
      current_user = users(:regular)
      users_profile = current_user

      refute UserPolicy.new(current_user, users_profile).index?

      refute UserPolicy.new(current_user, users_profile).create?
      refute UserPolicy.new(current_user, users_profile).new?

      assert UserPolicy.new(current_user, users_profile).show?
      assert UserPolicy.new(current_user, users_profile).edit?
      assert UserPolicy.new(current_user, users_profile).update?
      assert UserPolicy.new(current_user, users_profile).destroy?
    end

    should 'deny access to other users' do
      current_user = users(:regular)
      users_profile = users(:admin)

      refute UserPolicy.new(current_user, users_profile).index?

      refute UserPolicy.new(current_user, users_profile).create?
      refute UserPolicy.new(current_user, users_profile).new?

      refute UserPolicy.new(current_user, users_profile).show?
      refute UserPolicy.new(current_user, users_profile).edit?
      refute UserPolicy.new(current_user, users_profile).update?
      refute UserPolicy.new(current_user, users_profile).destroy?
    end
  end

  context 'anon user' do
    should 'deny access to other users' do
      current_user = nil
      users_profile = users(:admin)

      refute UserPolicy.new(current_user, users_profile).index?

      refute UserPolicy.new(current_user, users_profile).create?
      refute UserPolicy.new(current_user, users_profile).new?

      refute UserPolicy.new(current_user, users_profile).show?
      refute UserPolicy.new(current_user, users_profile).edit?
      refute UserPolicy.new(current_user, users_profile).update?
      refute UserPolicy.new(current_user, users_profile).destroy?
    end
  end

end
