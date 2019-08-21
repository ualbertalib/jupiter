require 'test_helper'

class ArCommunityTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :books).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'can be made into a draft' do
    ar_collection = ArCommunity.from_community(@community)

    draft_community = ArCommunity.from_community(@community, for_user: users(:admin))
    assert_equal @community.id, ar_collection.id
    assert_equal @community.description, ar_collection.description
  end

    assert draft_community.persisted?
    assert_equal @community.id, draft_community.community_id
    assert_equal @community.description, draft_community.description
  end
end
