require 'test_helper'

class ArCommunityTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :books).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'can be made into a draft' do
    ar_collection = ArCommunity.from_community(@community)

    assert ar_collection.persisted?
    assert_equal @community.id, ar_collection.id
    assert_equal @community.description, ar_collection.description
  end

end
