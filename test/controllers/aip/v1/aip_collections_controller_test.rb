require 'test_helper'
require 'support/aip_helper'

class Aip::V1::CollectionsControllerTest < ActionDispatch::IntegrationTest

  include AipHelper

  def setup
    @regular_user = users(:user_regular)

    community = communities(:community_books)
    @collection = Collection.new(title: 'AIP Collection',
                                 owner_id: users(:user_regular).id,
                                 community_id: community.id,
                                 id: 'a93cbb63-4bb2-4deb-a952-c96c4c851c8c',
                                 visibility: JupiterCore::VISIBILITY_PUBLIC,
                                 record_created_at: Date.parse('2015-12-12'),
                                 description: 'Collection description',
                                 restricted: false,
                                 created_at: Date.parse('2015-12-12'))
    @collection.save!
  end

  test 'should be able to show a visible collection to system user' do
    sign_in_as_system_user
    get aip_v1_collection_url(
      id: @collection
    )

    assert_response :success
  end

  test 'should not be able to show a visible collection to user' do
    sign_in_as @regular_user
    get aip_v1_collection_url(
      id: @collection
    )

    assert_response :redirect
  end

  test 'should get collection metadata graph with n3 serialization' do
    sign_in_as_system_user
    get aip_v1_collection_url(
      id: @collection
    )

    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_n3_graph(file_fixture('n3/collections/a93cbb63-4bb2-4deb-a952-c96c4c851c8c.n3'))

    assert_equal rendered_graph, graph
  end

  test 'should get collection metadata graph with n3 serialization even when description is nil' do
    @collection.assign_attributes(description: nil)
    @collection.save!
    sign_in_as_system_user
    get aip_v1_collection_url(
      id: @collection
    )

    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_n3_graph(
      file_fixture('n3/collections/a93cbb63-4bb2-4deb-a952-c96c4c851c8c_nil_description.n3')
    )

    assert_equal rendered_graph, graph
  end

  test 'should get collection metadata graph with n3 serialization even when description is markdown' do
    # specifically we want to make sure that any URLs are preserved
    @collection.assign_attributes(description: '[Collection description](https://example.com)')
    @collection.save!
    sign_in_as_system_user
    get aip_v1_collection_url(
      id: @collection
    )

    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_n3_graph(
      file_fixture('n3/collections/a93cbb63-4bb2-4deb-a952-c96c4c851c8c_markdown_description.n3')
    )

    assert_equal rendered_graph, graph
  end

end
