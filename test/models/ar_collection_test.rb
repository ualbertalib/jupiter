require 'test_helper'

class ArCollectionTest < ActiveSupport::TestCase

  def before_all
    super
    @community = locked_ldp_fixture(Community, :books).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :books).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'can be made into a draft' do
    # foreign key constraints won't allow invalid user IDs to own this collection
    User.new(id: @collection.owner, email: 'fake@1234.com', name: 'fake').save(validate: false)

    ar_collection = ArCollection.from_collection(@collection)

    assert ar_collection.persisted?
    assert_equal @collection.id, ar_collection.id
    assert_equal @collection.community.id, ar_collection.community_id
    assert_equal @collection.description, ar_collection.description
  end

end
