require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:community_books)
    @collection = collections(:collection_fantasy)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
