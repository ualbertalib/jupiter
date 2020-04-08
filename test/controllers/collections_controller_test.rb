require 'test_helper'

class CollectionsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:books)
    @collection = collections(:fantasy_books)
  end

  test 'should show collection' do
    get community_collection_url(@community, @collection)
    assert_response :success
  end

end
