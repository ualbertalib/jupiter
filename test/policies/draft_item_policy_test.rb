require 'test_helper'

class DraftItemPolicyTest < ActiveSupport::TestCase

  test 'admin user should be able to do everything' do
    current_user = users(:admin)
    draft_item = draft_items(:inactive)

    assert DraftItemPolicy.new(current_user, draft_item).create?
    assert DraftItemPolicy.new(current_user, draft_item).show?
    assert DraftItemPolicy.new(current_user, draft_item).update?
    assert DraftItemPolicy.new(current_user, draft_item).destroy?
    assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert DraftItemPolicy.new(current_user, draft_item).file_create?
    assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test 'general user should be able to do everything on their own item drafts' do
    current_user = users(:regular)
    draft_item = draft_items(:inactive) # belongs to regular user (current user) in this case

    assert DraftItemPolicy.new(current_user, draft_item).create?
    assert DraftItemPolicy.new(current_user, draft_item).show?
    assert DraftItemPolicy.new(current_user, draft_item).update?
    assert DraftItemPolicy.new(current_user, draft_item).destroy?
    assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    assert DraftItemPolicy.new(current_user, draft_item).file_create?
    assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test "general user should not be able to do anything on other's item drafts" do
    current_user = users(:regular_two)
    draft_item = draft_items(:inactive) # belongs to other user

    refute DraftItemPolicy.new(current_user, draft_item).create?
    refute DraftItemPolicy.new(current_user, draft_item).show?
    refute DraftItemPolicy.new(current_user, draft_item).update?
    refute DraftItemPolicy.new(current_user, draft_item).destroy?
    refute DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    refute DraftItemPolicy.new(current_user, draft_item).file_create?
    refute DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

  test 'anon user should not be able to do anything with item drafts' do
    current_user = nil
    draft_item = draft_items(:inactive)

    refute DraftItemPolicy.new(current_user, draft_item).create?
    refute DraftItemPolicy.new(current_user, draft_item).show?
    refute DraftItemPolicy.new(current_user, draft_item).update?
    refute DraftItemPolicy.new(current_user, draft_item).destroy?
    refute DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
    refute DraftItemPolicy.new(current_user, draft_item).file_create?
    refute DraftItemPolicy.new(current_user, draft_item).file_destroy?
  end

end
