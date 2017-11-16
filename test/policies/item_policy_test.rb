require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  context 'admin user' do
    should 'have proper authorization over items' do
      current_user = users(:admin)
      item = Item.new_locked_ldp_object

      assert ItemPolicy.new(current_user, item).index?
      assert ItemPolicy.new(current_user, item).create?
      assert ItemPolicy.new(current_user, item).new?
      assert ItemPolicy.new(current_user, item).show?
      assert ItemPolicy.new(current_user, item).edit?
      assert ItemPolicy.new(current_user, item).update?
      assert ItemPolicy.new(current_user, item).destroy?
    end
  end

  context 'general user' do
    should 'only be able to create, see and modify, but not delete, your own items' do
      current_user = users(:regular_user)
      item = Item.new_locked_ldp_object(owner: current_user.id)

      assert ItemPolicy.new(current_user, item).index?
      assert ItemPolicy.new(current_user, item).show?
      assert ItemPolicy.new(current_user, item).edit?
      assert ItemPolicy.new(current_user, item).update?

      assert ItemPolicy.new(current_user, item).create?
      assert ItemPolicy.new(current_user, item).new?
      refute ItemPolicy.new(current_user, item).destroy?
    end

    should 'not have access to other items' do
      current_user = users(:regular_user)
      another_user = users(:admin)

      item = Item.new_locked_ldp_object(owner: another_user.id, visibility: JupiterCore::VISIBILITY_PUBLIC)

      assert ItemPolicy.new(current_user, item).index?
      assert ItemPolicy.new(current_user, item).show?

      refute ItemPolicy.new(current_user, item).edit?
      refute ItemPolicy.new(current_user, item).update?
      refute ItemPolicy.new(current_user, item).destroy?
    end
  end

  context 'anon user' do
    should 'only be able to see index and show of items' do
      current_user = nil
      item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC)

      assert ItemPolicy.new(current_user, item).index?
      assert ItemPolicy.new(current_user, item).show?

      refute ItemPolicy.new(current_user, item).create?
      refute ItemPolicy.new(current_user, item).new?
      refute ItemPolicy.new(current_user, item).edit?
      refute ItemPolicy.new(current_user, item).update?
      refute ItemPolicy.new(current_user, item).destroy?
    end
  end

end
