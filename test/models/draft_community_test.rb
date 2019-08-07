require 'test_helper'

class DraftCommunityTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :books).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'can be made into a draft' do
    # foreign key constraints won't allow invalid user IDs to own this collection
    User.new(id: @community.owner, email: 'fake@1234.com', name: 'fake').save(validate: false)

    draft_community = DraftCommunity.from_community(@community, for_user: users(:admin))

    assert draft_community.persisted?
    assert_equal @community.id, draft_community.community_id
    assert_equal @community.description, draft_community.description
  end

end
