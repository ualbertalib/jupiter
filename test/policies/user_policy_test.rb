require 'test_helper'

class UserPolicyTest < ActiveSupport::TestCase

  test 'admin user should have proper authorization over other users' do
    current_user = users(:user_admin)
    users_profile = users(:user_regular)

    assert_predicate UserPolicy.new(current_user, users_profile), :index?

    assert_not UserPolicy.new(current_user, users_profile).create?
    assert_not UserPolicy.new(current_user, users_profile).new?

    assert_predicate UserPolicy.new(current_user, users_profile), :show?
    assert_predicate UserPolicy.new(current_user, users_profile), :edit?
    assert_predicate UserPolicy.new(current_user, users_profile), :update?
    assert_predicate UserPolicy.new(current_user, users_profile), :destroy?
  end

  test 'should allow regular user access to yourself' do
    current_user = users(:user_regular)
    users_profile = current_user

    assert_not UserPolicy.new(current_user, users_profile).index?

    assert_not UserPolicy.new(current_user, users_profile).create?
    assert_not UserPolicy.new(current_user, users_profile).new?

    assert_predicate UserPolicy.new(current_user, users_profile), :show?
    assert_predicate UserPolicy.new(current_user, users_profile), :edit?
    assert_predicate UserPolicy.new(current_user, users_profile), :update?
    assert_predicate UserPolicy.new(current_user, users_profile), :destroy?
  end

  test 'should deny access to other regular users' do
    current_user = users(:user_regular)
    users_profile = users(:user_admin)

    assert_not UserPolicy.new(current_user, users_profile).index?

    assert_not UserPolicy.new(current_user, users_profile).create?
    assert_not UserPolicy.new(current_user, users_profile).new?

    assert_not UserPolicy.new(current_user, users_profile).show?
    assert_not UserPolicy.new(current_user, users_profile).edit?
    assert_not UserPolicy.new(current_user, users_profile).update?
    assert_not UserPolicy.new(current_user, users_profile).destroy?
  end

  test 'should deny access to other anonymous users' do
    current_user = nil
    users_profile = users(:user_admin)

    assert_not UserPolicy.new(current_user, users_profile).index?

    assert_not UserPolicy.new(current_user, users_profile).create?
    assert_not UserPolicy.new(current_user, users_profile).new?

    assert_not UserPolicy.new(current_user, users_profile).show?
    assert_not UserPolicy.new(current_user, users_profile).edit?
    assert_not UserPolicy.new(current_user, users_profile).update?
    assert_not UserPolicy.new(current_user, users_profile).destroy?
  end

end
