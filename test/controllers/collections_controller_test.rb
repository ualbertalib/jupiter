require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new(title: 'Nice community', owner_id: 1).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new(title: 'Nice collection', owner_id: 1, community_id: @community.id).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
