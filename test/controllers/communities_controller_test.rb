require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @community = communities(:community_books)
  end

  test 'should get index' do
    get communities_url

    assert_response :success
  end

  test 'should show community' do
    get community_url(@community)

    assert_response :success
  end

  test 'should show community js' do
    get community_url(@community, format: :js), xhr: true

    assert_response :success
  end

  test 'should show community json' do
    get community_url(@community, format: :json)

    assert_response :success
  end

end
