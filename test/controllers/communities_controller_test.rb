require 'test_helper'

class CommunitiesControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = Community.new(title: 'Nice community',
                                                 owner_id: 1)
    @community.unlock_and_fetch_ldp_object(&:save!)
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
