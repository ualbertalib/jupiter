require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new_locked_ldp_object(title: 'Nice community',
                                                 owner: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(community_id: @community.id,
                                                   title: 'Nice collection',
                                                   owner: 1)
    @collection.unlock_and_fetch_ldp_object(&:save!)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
