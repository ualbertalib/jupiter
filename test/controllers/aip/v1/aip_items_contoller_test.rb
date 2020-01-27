require 'test_helper'

class Aip::V1::ItemsControllerTest < ActionDispatch::IntegrationTest

  include AipActions

  # Transactional tests were creating a problem where a collection defined as a
  # fixture would only be found sometimes (a race condition?)
  self.use_transactional_tests = false

  def setup
    @admin_user = users(:admin)
    @regular_user = users(:regular)
    @public_model = items(:fancy)
    @private_model = items(:fancy_private)
    @model = Item.name.underscore.pluralize
  end

  test 'should be able to show a visible item' do
    sign_in_as @regular_user
    get aip_v1_model_url(
      id: @public_model,
      model: @model
    )
    assert_response :success
  end

  test 'should not be able to show a private item' do
    sign_in_as @regular_user
    get aip_v1_model_url(
      id: @private_model,
      model: @model
    )
    assert_response :redirect
  end

  # Basic test checking if response has n3 serialization.
  test 'should get item metadata graph with n3 serialization' do
    sign_in_as @admin_user
    get aip_v1_model_url(
      model: @model,
      id: @public_model
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    assert_equal true, graph.graph?
  end

  # Basic test checking if response has xml format.
  test 'should get item filesets order in xml format' do
    sign_in_as @admin_user
    get aip_v1_model_filesets_url(
      model: @model,
      id: @public_model
    )

    assert_response :success

    assert_equal true, check_file_order_xml(response.body)
  end

end
