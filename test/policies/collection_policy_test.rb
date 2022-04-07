require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  test 'admin user should have proper authorization over collections' do
    current_user = users(:user_admin)
    collection = Collection.new

    assert_predicate CollectionPolicy.new(current_user, collection), :index?
    assert_predicate CollectionPolicy.new(current_user, collection), :create?
    assert_predicate CollectionPolicy.new(current_user, collection), :new?
    assert_predicate CollectionPolicy.new(current_user, collection), :show?
    assert_predicate CollectionPolicy.new(current_user, collection), :edit?
    assert_predicate CollectionPolicy.new(current_user, collection), :update?
    assert_predicate CollectionPolicy.new(current_user, collection), :destroy?
  end

  test 'general user should only be able to see index and show of collections' do
    current_user = users(:user_regular)
    collection = Collection.new

    assert_predicate CollectionPolicy.new(current_user, collection), :index?
    assert_predicate CollectionPolicy.new(current_user, collection), :show?

    assert_not CollectionPolicy.new(current_user, collection).create?
    assert_not CollectionPolicy.new(current_user, collection).new?
    assert_not CollectionPolicy.new(current_user, collection).edit?
    assert_not CollectionPolicy.new(current_user, collection).update?
    assert_not CollectionPolicy.new(current_user, collection).destroy?
  end

  test 'anon user should only be able to see index and show of collections' do
    current_user = nil
    collection = Collection.new

    assert_predicate CollectionPolicy.new(current_user, collection), :index?
    assert_predicate CollectionPolicy.new(current_user, collection), :show?

    assert_not CollectionPolicy.new(current_user, collection).create?
    assert_not CollectionPolicy.new(current_user, collection).new?
    assert_not CollectionPolicy.new(current_user, collection).edit?
    assert_not CollectionPolicy.new(current_user, collection).update?
    assert_not CollectionPolicy.new(current_user, collection).destroy?
  end

end
