require 'test_helper'

class CommunityPolicyTest < ActiveSupport::TestCase

  test 'admin user should have proper authorization over communities' do
    current_user = users(:user_admin)
    community = Community.new

    assert_predicate CommunityPolicy.new(current_user, community), :index?
    assert_predicate CommunityPolicy.new(current_user, community), :create?
    assert_predicate CommunityPolicy.new(current_user, community), :new?
    assert_predicate CommunityPolicy.new(current_user, community), :show?
    assert_predicate CommunityPolicy.new(current_user, community), :edit?
    assert_predicate CommunityPolicy.new(current_user, community), :update?
    assert_predicate CommunityPolicy.new(current_user, community), :destroy?
  end

  test 'general user should only be able to see index and show of communities' do
    current_user = users(:user_regular)
    community = Community.new

    assert_predicate CommunityPolicy.new(current_user, community), :index?
    assert_predicate CommunityPolicy.new(current_user, community), :show?

    assert_not CommunityPolicy.new(current_user, community).create?
    assert_not CommunityPolicy.new(current_user, community).new?
    assert_not CommunityPolicy.new(current_user, community).edit?
    assert_not CommunityPolicy.new(current_user, community).update?
    assert_not CommunityPolicy.new(current_user, community).destroy?
  end

  test 'anon user should only be able to see index and show of communities' do
    current_user = nil
    community = Community.new

    assert_predicate CommunityPolicy.new(current_user, community), :index?
    assert_predicate CommunityPolicy.new(current_user, community), :show?

    assert_not CommunityPolicy.new(current_user, community).create?
    assert_not CommunityPolicy.new(current_user, community).new?
    assert_not CommunityPolicy.new(current_user, community).edit?
    assert_not CommunityPolicy.new(current_user, community).update?
    assert_not CommunityPolicy.new(current_user, community).destroy?
  end

end
