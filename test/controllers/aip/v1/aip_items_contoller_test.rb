require 'test_helper'
require Rails.root.join('test/support/aip_helper')

class Aip::V1::ItemsControllerTest < ActionDispatch::IntegrationTest

  include AipHelper

  setup do
    @regular_user = users(:regular)
    @private_item = items(:private_item)
    @entity = Item.table_name

    @public_item = create_entity(
      entity_class: Item,
      parameters: {
        visibility: JupiterCore::VISIBILITY_PUBLIC,
        owner_id: users(:admin).id,
        title: 'Item with files',
        creators: ['Joe Blow'],
        created: '1000000 BC',
        languages: [CONTROLLED_VOCABULARIES[:language].english],
        item_type: CONTROLLED_VOCABULARIES[:item_type].article,
        publication_status: [CONTROLLED_VOCABULARIES[:publication_status].published],
        license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
        subject: ['Items']
      },
      files: [
        file_fixture('image-sample.jpeg'),
        file_fixture('text-sample.txt')
      ]
    )

    # Load just the RDF annotations we need for these tests
    seed_active_storage_blobs_rdf_annotations
    seed_item_rdf_annotations
  end

  test 'should be able to show a visible item to admin' do
    sign_in_as_system_user
    get aip_v1_entity_url(
      id: @public_item,
      entity: @entity
    )
    assert_response :success
  end

  test 'should not be able to show a visible item to user' do
    sign_in_as @regular_user
    get aip_v1_entity_url(
      id: @public_item,
      entity: @entity
    )
    assert_response :redirect
  end

  test 'should not be able to show a private item to user' do
    sign_in_as @regular_user
    get aip_v1_entity_url(
      id: @public_item,
      entity: @entity
    )
    assert_response :redirect
  end

  test 'should get item metadata graph with n3 serialization for base example including hasMember predicates' do
    radioactive_item = items(:admin)
    radioactive_item.id = 'e2ec88e3-3266-4e95-8575-8b04fac2a679'
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    sign_in_as_system_user

    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_item.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_item, 'base')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get item metadata graph with n3 serialization for embargo example' do
    radioactive_item = items(:admin)
    radioactive_item.id = '3bb26070-0d25-4f0e-b44f-e9879da333ec'
    radioactive_item.visibility = Item::VISIBILITY_EMBARGO
    radioactive_item.embargo_history = ['acl:embargoHistory1$ Item currently embargoed'.freeze]
    radioactive_item.embargo_end_date = '2080-01-01T00:00:00.000Z'.freeze
    radioactive_item.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_item.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_item, 'embargoed')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get item metadata graph with n3 serialization for previously embargoed example' do
    radioactive_item = items(:admin)
    radioactive_item.id = '2107bfb6-2670-4ffc-94a1-aeb4f8c1fd81'
    radioactive_item.visibility = Item::VISIBILITY_EMBARGO
    radioactive_item.embargo_end_date = '2000-01-01T00:00:00.000Z'
    radioactive_item.embargo_history = [
      'acl:embargoHistory1$ An expired embargo was deactivated on 2000-01-01T00:00:00.000Z.  Its release date was ' \
      '2000-01-01T00:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo was ' \
      'open'.freeze,
      'acl:embargoHistory2$ An expired embargo was deactivated on 2000-01-01T00:00:00.000Z.  Its release date was ' \
      '2000-01-01T00:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo was ' \
      'open'.freeze
    ]
    radioactive_item.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_item.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_item, 'prev-embargoed')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get item metadata graph with n3 serialization for rights example' do
    radioactive_item = items(:admin)
    radioactive_item.id = 'c795337f-075f-429a-bb18-16b56d9b750f'
    radioactive_item.license = ''
    radioactive_item.rights = '© The Author(s) 2015. Published by Oxford University Press on behalf of the Society ' \
                              'for Molecular Biology and Evolution.'.freeze
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_item.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_item, 'rights')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get item metadata graph with n3 serialization for published status example' do
    radioactive_item = items(:admin)
    radioactive_item.id = '93126aae-4b9d-4db2-98f1-4e04b40778cf'
    radioactive_item.item_type = CONTROLLED_VOCABULARIES[:item_type].article
    radioactive_item.publication_status = [CONTROLLED_VOCABULARIES[:publication_status].published]
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_item.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_item, 'published-status')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  # Basic test checking if response has xml format.
  test 'should get item filesets order in xml format' do
    sign_in_as_system_user
    get aip_v1_entity_filesets_url(
      entity: @entity,
      id: @public_item
    )

    assert_response :success

    assert_equal true, check_file_order_xml(response.body)
  end

  test 'should get item file paths' do
    sign_in_as_system_user
    get aip_v1_entity_file_paths_url(
      entity: @entity,
      id: @public_item
    )
    assert_response :success
    json_string = response.body
    assert_equal true, JSON::Validator.validate(
      file_paths_json_schema,
      json_string
    )
    json_response = JSON.parse(json_string)

    # Check that all files actually exist
    json_response['files'].map do |file_path|
      assert_equal true, File.file?(file_path['file_path'])
    end
  end

  # Basic tests checking if response has n3 serialization.
  # This should be changed to verify the response content is correct.

  test 'should get item file set metadata graph with n3 serialization' do
    sign_in_as_system_user

    radioactive_item = items(:admin)
    radioactive_item.id = 'e2ec88e3-3266-4e95-8575-8b04fac2a679'
    ingest_files_for_entity(radioactive_item)
    radioactive_item.save!
    radioactive_item.reload

    get aip_v1_entity_file_set_url(
      entity: @entity,
      id: radioactive_item,
      file_set_id: radioactive_item.files.first.fileset_uuid
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)

    variables = {
      fileset_id: radioactive_item.files.first.fileset_uuid,
      collection_id: radioactive_item.member_of_paths.first.split('/')[1]
    }
    rendered_graph = load_n3_graph(file_fixture('n3/items/file_set.n3'), variables)

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get item fixity metadata graph with n3 serialization' do
    sign_in_as_system_user
    url = aip_v1_entity_fileset_fixity_url(
      entity: @entity,
      id: @public_item,
      file_set_id: @public_item.files.first.fileset_uuid
    )

    graph = get_n3_graph(url)
    assert_response :success

    variables = {
      entity_id: @public_item.id,
      fileset_id: @public_item.files.first.fileset_uuid,
      checksum: @public_item.files.first.blob.checksum,
      byte_size: @public_item.files.first.blob.byte_size
    }
    rendered_graph = load_n3_graph(file_fixture('n3/items/fixity.n3'), variables)

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

end
