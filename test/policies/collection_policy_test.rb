require 'test_helper'

class CollectionPolicyTest < ActiveSupport::TestCase

  test 'admin user should have proper authorization over collections' do
    current_user = users(:admin)
    collection = Collection.new_locked_ldp_object

    assert CollectionPolicy.new(current_user, collection).index?
    assert CollectionPolicy.new(current_user, collection).create?
    assert CollectionPolicy.new(current_user, collection).new?
    assert CollectionPolicy.new(current_user, collection).show?
    assert CollectionPolicy.new(current_user, collection).edit?
    assert CollectionPolicy.new(current_user, collection).update?
    assert CollectionPolicy.new(current_user, collection).destroy?
  end

  test 'general user should only be able to see index and show of collections' do
    current_user = users(:regular)
    collection = Collection.new_locked_ldp_object

    assert CollectionPolicy.new(current_user, collection).index?
    assert CollectionPolicy.new(current_user, collection).show?

    assert_not CollectionPolicy.new(current_user, collection).create?
    assert_not CollectionPolicy.new(current_user, collection).new?
    assert_not CollectionPolicy.new(current_user, collection).edit?
    assert_not CollectionPolicy.new(current_user, collection).update?
    assert_not CollectionPolicy.new(current_user, collection).destroy?
  end

  test 'anon user should only be able to see index and show of collections' do
    current_user = nil
    collection = Collection.new_locked_ldp_object

    assert CollectionPolicy.new(current_user, collection).index?
    assert CollectionPolicy.new(current_user, collection).show?

    assert_not CollectionPolicy.new(current_user, collection).create?
    assert_not CollectionPolicy.new(current_user, collection).new?
    assert_not CollectionPolicy.new(current_user, collection).edit?
    assert_not CollectionPolicy.new(current_user, collection).update?
    assert_not CollectionPolicy.new(current_user, collection).destroy?
  end

end
