require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = locked_ldp_fixture(Community, :nice).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :nice).unlock_and_fetch_ldp_object(&:save!)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
