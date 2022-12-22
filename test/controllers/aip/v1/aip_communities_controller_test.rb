require 'test_helper'
require 'support/aip_helper'

class Aip::V1::CommunitiesControllerTest < ActionDispatch::IntegrationTest

  include AipHelper

  def setup
    @regular_user = users(:user_regular)

    @community = Community.new(title: 'AIP Community',
                               owner_id: users(:user_regular).id,
                               id: '2614825c-aafa-47ca-a84b-8d81c30147c5',
                               visibility: JupiterCore::VISIBILITY_PUBLIC,
                               record_created_at: Date.parse('2015-12-12'),
                               created_at: Date.parse('2015-12-12'),
                               description: 'Community description')
    @community.save!
  end

  test 'should be able to show a visible community to system user' do
    sign_in_as_system_user
    get aip_v1_community_url(
      id: @community
    )
    assert_response :success
  end

  test 'should not be able to show a visible community to user' do
    sign_in_as @regular_user
    get aip_v1_community_url(
      id: @community
    )
    assert_response :redirect
  end

  test 'should get community metadata graph with n3 serialization' do
    sign_in_as_system_user

    get aip_v1_community_url(
      id: @community
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_n3_graph(file_fixture('n3/communities/2614825c-aafa-47ca-a84b-8d81c30147c5.n3'))

    assert_equal rendered_graph, graph
  end

end
