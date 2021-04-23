require 'test_helper'

class DraftItemPolicyTest < ActiveSupport::TestCase

  test 'admin user should be able to do everything' do
    current_user = users(:user_admin)
    draft_item = draft_items(:draft_item_inactive)

    assert DraftItemPolicy.new(current_user, draft_item).create?
    assert DraftItemPolicy.new(current_user, draft_item).show?
    assert DraftItemPolicy.new(current_user, draft_item).update?
    assert DraftItemPolicy.new(current_user, draft_item).destroy?
    assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert DraftItemPolicy.new(current_user, draft_item).file_create?
    assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test 'general user should be able to do everything on their own item drafts' do
    current_user = users(:user_regular)
    draft_item = draft_items(:draft_item_inactive) # belongs to regular user (current user) in this case

    assert DraftItemPolicy.new(current_user, draft_item).create?
    assert DraftItemPolicy.new(current_user, draft_item).show?
    assert DraftItemPolicy.new(current_user, draft_item).update?
    assert DraftItemPolicy.new(current_user, draft_item).destroy?
    assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert DraftItemPolicy.new(current_user, draft_item).file_create?
    assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test "general user should not be able to do anything on other's item drafts" do
    current_user = users(:user_regular_two)
    draft_item = draft_items(:draft_item_inactive) # belongs to other user

    assert_not DraftItemPolicy.new(current_user, draft_item).create?
    assert_not DraftItemPolicy.new(current_user, draft_item).show?
    assert_not DraftItemPolicy.new(current_user, draft_item).update?
    assert_not DraftItemPolicy.new(current_user, draft_item).destroy?
    assert_not DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert_not DraftItemPolicy.new(current_user, draft_item).file_create?
    assert_not DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test 'anon user should not be able to do anything with item drafts' do
    current_user = nil
    draft_item = draft_items(:draft_item_inactive)

    assert_not DraftItemPolicy.new(current_user, draft_item).create?
    assert_not DraftItemPolicy.new(current_user, draft_item).show?
    assert_not DraftItemPolicy.new(current_user, draft_item).update?
    assert_not DraftItemPolicy.new(current_user, draft_item).destroy?
    assert_not DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert_not DraftItemPolicy.new(current_user, draft_item).file_create?
    assert_not DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

end
