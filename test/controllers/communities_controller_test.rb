require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:books)
  end

  test 'should get index' do
    get communities_url
    assert_response :success
  end

  test 'should show community' do
    get community_url(@community)
    assert_response :success
  end

end
