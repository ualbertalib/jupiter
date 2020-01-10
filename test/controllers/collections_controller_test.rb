require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.create!(title: 'Nice community', owner_id: users(:admin).id)
    @collection = Collection.create!(title: 'Nice collection', owner_id: users(:admin).id, community_id: @community.id)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
