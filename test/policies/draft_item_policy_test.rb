require 'test_helper'

class DraftItemPolicyTest < ActiveSupport::TestCase

  def before_all
    @community = Community.new_locked_ldp_object(title: 'Books', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Fantasy Books',
                                                   owner: 1,
                                                   community_id: @community.id)
                            .unlock_and_fetch_ldp_object(&:save!)
    @restricted_collection = Collection.new_locked_ldp_object(title: 'Risque Fantasy Books',
                                                              owner: 1,
                                                              restricted: true,
                                                              community_id: @community.id)
                                       .unlock_and_fetch_ldp_object(&:save!)
  end

  context 'admin user' do
    should 'be able to do everything in an unrestricted collection' do
      current_user = users(:admin)
      draft_item = draft_items(:inactive)
      draft_item.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }

      assert DraftItemPolicy.new(current_user, draft_item).create?
      assert DraftItemPolicy.new(current_user, draft_item).show?
      assert DraftItemPolicy.new(current_user, draft_item).update?
      assert DraftItemPolicy.new(current_user, draft_item).destroy?
      assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
      assert DraftItemPolicy.new(current_user, draft_item).file_create?
      assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
    end

    should 'be able to do everything in a restricted collection' do
      current_user = users(:admin)
      draft_item = draft_items(:inactive)
      draft_item.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@restricted_collection.id] }

      assert DraftItemPolicy.new(current_user, draft_item).create?
      assert DraftItemPolicy.new(current_user, draft_item).show?
      assert DraftItemPolicy.new(current_user, draft_item).update?
      assert DraftItemPolicy.new(current_user, draft_item).destroy?
      assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
      assert DraftItemPolicy.new(current_user, draft_item).file_create?
      assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
    end
  end

  context 'general user' do
    should 'be able to do everything on their own item drafts in an unrestricted collection' do
      current_user = users(:regular)
      draft_item = draft_items(:inactive) # belongs to regular user (current user) in this case
      draft_item.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@collection.id] }

      assert DraftItemPolicy.new(current_user, draft_item).create?
      assert DraftItemPolicy.new(current_user, draft_item).show?
      assert DraftItemPolicy.new(current_user, draft_item).update?
      assert DraftItemPolicy.new(current_user, draft_item).destroy?
      assert DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
      assert DraftItemPolicy.new(current_user, draft_item).file_create?
      assert DraftItemPolicy.new(current_user, draft_item).file_destroy?
    end

    should 'be not be able to do anything on their own item drafts in a restricted collection' do
      current_user = users(:regular)
      draft_item = draft_items(:inactive) # belongs to regular user (current user) in this case
      draft_item.member_of_paths = { 'community_id': [@community.id], 'collection_id': [@restricted_collection.id] }

      refute DraftItemPolicy.new(current_user, draft_item).create?
      refute DraftItemPolicy.new(current_user, draft_item).show?
      refute DraftItemPolicy.new(current_user, draft_item).update?
      refute DraftItemPolicy.new(current_user, draft_item).destroy?
      refute DraftItemPolicy.new(current_user, draft_item).set_thumbnail?
      refute DraftItemPolicy.new(current_user, draft_item).file_create?
      refute DraftItemPolicy.new(current_user, draft_item).file_destroy?
    end

    should "not be able to do anything on other's item drafts" do
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
  end

  context 'anon user' do
    should 'not be able to do anything with item drafts' do
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

end
