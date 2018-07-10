require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  test 'admin should have proper authorization over items' do
    current_user = users(:admin)
    item = Item.new_locked_ldp_object

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).create?
    assert ItemPolicy.new(current_user, item).new?
    assert ItemPolicy.new(current_user, item).show?
    assert ItemPolicy.new(current_user, item).edit?
    assert ItemPolicy.new(current_user, item).update?
    assert ItemPolicy.new(current_user, item).destroy?
    assert ItemPolicy.new(current_user, item).download?
    assert ItemPolicy.new(current_user, item).thumbnail?
  end

  test 'authenticated user should only be able to create, see and modify, but not delete, their own items' do
    current_user = users(:regular)
    item = Item.new_locked_ldp_object(owner: current_user.id)

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).show?
    assert ItemPolicy.new(current_user, item).edit?
    assert ItemPolicy.new(current_user, item).update?

    assert ItemPolicy.new(current_user, item).create?
    assert ItemPolicy.new(current_user, item).new?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'authenticated user should not have edit access to public items' do
    current_user = users(:regular)
    another_user = users(:admin)

    item = Item.new_locked_ldp_object(owner: another_user.id, visibility: JupiterCore::VISIBILITY_PUBLIC)

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).show?
    assert ItemPolicy.new(current_user, item).download?
    assert ItemPolicy.new(current_user, item).thumbnail?

    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'authenticated user should not have edit access to authenticated items' do
    current_user = users(:regular)
    another_user = users(:admin)

    item = Item.new_locked_ldp_object(owner: another_user.id, visibility: JupiterCore::VISIBILITY_AUTHENTICATED)

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).show?
    assert ItemPolicy.new(current_user, item).download?
    assert ItemPolicy.new(current_user, item).thumbnail?

    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'anon user should only be able to index, show, download, and view thumbnails of public items' do
    current_user = nil
    item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_PUBLIC)

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).show?
    assert ItemPolicy.new(current_user, item).download?
    assert ItemPolicy.new(current_user, item).thumbnail?

    assert_not ItemPolicy.new(current_user, item).create?
    assert_not ItemPolicy.new(current_user, item).new?
    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'anon user should only be able to index and show authenticated items' do
    current_user = nil
    item = Item.new_locked_ldp_object(visibility: JupiterCore::VISIBILITY_AUTHENTICATED)

    assert ItemPolicy.new(current_user, item).index?
    assert ItemPolicy.new(current_user, item).show?

    assert_not ItemPolicy.new(current_user, item).create?
    assert_not ItemPolicy.new(current_user, item).new?
    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
    assert_not ItemPolicy.new(current_user, item).download?
    assert_not ItemPolicy.new(current_user, item).thumbnail?
  end

end
