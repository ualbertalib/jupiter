require 'test_helper'

class ItemPolicyTest < ActiveSupport::TestCase

  test 'admin should have proper authorization over items' do
    current_user = users(:user_admin)
    item = Item.new

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :create?
    assert_predicate ItemPolicy.new(current_user, item), :new?
    assert_predicate ItemPolicy.new(current_user, item), :show?
    assert_predicate ItemPolicy.new(current_user, item), :edit?
    assert_predicate ItemPolicy.new(current_user, item), :update?
    assert_predicate ItemPolicy.new(current_user, item), :destroy?
    assert_predicate ItemPolicy.new(current_user, item), :download?
    assert_predicate ItemPolicy.new(current_user, item), :thumbnail?
  end

  test 'authenticated user should only be able to create, see and modify, but not delete, their own items' do
    current_user = users(:user_regular)
    item = Item.new(owner_id: current_user.id)

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :show?
    assert_predicate ItemPolicy.new(current_user, item), :edit?
    assert_predicate ItemPolicy.new(current_user, item), :update?

    assert_predicate ItemPolicy.new(current_user, item), :create?
    assert_predicate ItemPolicy.new(current_user, item), :new?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'authenticated user should not have edit access to public items' do
    current_user = users(:user_regular)
    another_user = users(:user_admin)

    item = Item.new(owner_id: another_user.id, visibility: JupiterCore::VISIBILITY_PUBLIC)

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :show?
    assert_predicate ItemPolicy.new(current_user, item), :download?
    assert_predicate ItemPolicy.new(current_user, item), :thumbnail?

    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'authenticated user should not have edit access to authenticated items' do
    current_user = users(:user_regular)
    another_user = users(:user_admin)

    item = Item.new(owner_id: another_user.id, visibility: JupiterCore::VISIBILITY_AUTHENTICATED)

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :show?
    assert_predicate ItemPolicy.new(current_user, item), :download?
    assert_predicate ItemPolicy.new(current_user, item), :thumbnail?

    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'anon user should only be able to index, show, download, and view thumbnails of public items' do
    current_user = nil
    item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC)

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :show?
    assert_predicate ItemPolicy.new(current_user, item), :download?
    assert_predicate ItemPolicy.new(current_user, item), :thumbnail?

    assert_not ItemPolicy.new(current_user, item).create?
    assert_not ItemPolicy.new(current_user, item).new?
    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
  end

  test 'anon user should only be able to index and show authenticated items' do
    current_user = nil
    item = Item.new(visibility: JupiterCore::VISIBILITY_AUTHENTICATED)

    assert_predicate ItemPolicy.new(current_user, item), :index?
    assert_predicate ItemPolicy.new(current_user, item), :show?

    assert_not ItemPolicy.new(current_user, item).create?
    assert_not ItemPolicy.new(current_user, item).new?
    assert_not ItemPolicy.new(current_user, item).edit?
    assert_not ItemPolicy.new(current_user, item).update?
    assert_not ItemPolicy.new(current_user, item).destroy?
    assert_not ItemPolicy.new(current_user, item).download?
    assert_not ItemPolicy.new(current_user, item).thumbnail?
  end

end
