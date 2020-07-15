require 'test_helper'
require Rails.root.join('test/support/aip_helper')

class Aip::V1::ThesesControllerTest < ActionDispatch::IntegrationTest

  include AipHelper

  setup do
    @system_user = users(:system_user)
    @regular_user = users(:regular)
    @private_thesis = thesis(:private)
    @entity = Thesis.table_name
    @public_thesis = create_entity(
      entity_class: Thesis,
      parameters: {
        title: 'Thesis with files',
        owner_id: @system_user.id,
        dissertant: 'Joe Blow',
        visibility: JupiterCore::VISIBILITY_PUBLIC,
        graduation_date: '2017-03-31'
      },
      files: [
        file_fixture('image-sample.jpeg'),
        file_fixture('text-sample.txt')
      ]
    )

    # Don't forget to load your rdf annotations!
    seed_active_storage_blobs_rdf_annotations
    seed_theses_rdf_annotations
  end

  test 'should be able to show a visible thesis to admin' do
    sign_in_as_system_user
    get aip_v1_entity_url(
      id: @public_thesis,
      entity: @entity
    )
    assert_response :success
  end

  test 'should not be able to show a visible thesis' do
    sign_in_as @regular_user
    get aip_v1_entity_url(
      id: @public_thesis,
      entity: @entity
    )
    assert_response :redirect
  end

  test 'should not be able to show a private thesis' do
    sign_in_as @regular_user
    get aip_v1_entity_url(
      id: @private_thesis,
      entity: @entity
    )
    assert_response :redirect
  end

  test 'should get thesis metadata graph with n3 serialization for base example' do
    radioactive_thesis = thesis(:admin)
    radioactive_thesis.id = '8e18f37c-dc60-41bb-9459-990586176730'.freeze
    ingest_files_for_entity(radioactive_thesis)
    radioactive_thesis.save!
    radioactive_thesis.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_thesis.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_thesis, 'base')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get thesis metadata graph with n3 serialization for embargo example' do
    radioactive_thesis = thesis(:admin)
    radioactive_thesis.id = 'b3cc2224-9303-47be-8b54-e6556a486be8'.freeze
    radioactive_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    radioactive_thesis.embargo_history = ['acl:embargoHistory1$ Thesis currently embargoed']
    radioactive_thesis.embargo_end_date = '2080-01-01T00:00:00.000Z'
    radioactive_thesis.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
    ingest_files_for_entity(radioactive_thesis)
    radioactive_thesis.save!
    radioactive_thesis.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_thesis.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_thesis, 'embargoed')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  test 'should get thesis metadata graph with n3 serialization for previously embargo example' do
    radioactive_thesis = thesis(:admin)
    radioactive_thesis.id = '9d7c12f0-b396-4511-ba0e-c012ec028e8a'
    radioactive_thesis.visibility = Thesis::VISIBILITY_EMBARGO
    radioactive_thesis.embargo_end_date = '2000-01-01T00:00:00.000Z'
    radioactive_thesis.embargo_history = [
      'acl:embargoHistory1$ An expired embargo was deactivated on 2016-06-15T18:00:15.651Z.  Its release date was ' \
      '2016-06-15T06:00:00.000Z.  Visibility during embargo was restricted and intended visibility after embargo was ' \
      'open'
    ]
    radioactive_thesis.visibility_after_embargo = CONTROLLED_VOCABULARIES[:visibility].public
    ingest_files_for_entity(radioactive_thesis)
    radioactive_thesis.save!
    radioactive_thesis.reload

    sign_in_as_system_user
    get aip_v1_entity_url(
      entity: @entity,
      id: radioactive_thesis.id
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    rendered_graph = load_radioactive_n3_graph(radioactive_thesis, 'prev-embargoed')

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  # Basic test checking if response has xml format.
  test 'should get thesis filesets order in xml format' do
    sign_in_as_system_user
    get aip_v1_entity_filesets_url(
      entity: @entity,
      id: @public_thesis
    )

    assert_response :success
    assert_equal true, check_file_order_xml(response.body)
  end

  test 'should get thesis file paths' do
    sign_in_as_system_user
    get aip_v1_entity_file_paths_url(
      entity: @entity,
      id: @public_thesis
    )
    assert_response :success
    json_string = response.body
    assert_equal true, JSON::Validator.validate(
      file_paths_json_schema,
      json_string
    )
    json_response = JSON.parse(json_string)

    # Check that all files actually exist
    json_response['files'].map do |file|
      assert_equal true, File.file?(file['file_path'])
    end
  end

  # Basic tests checking if response has n3 serialization.
  # This should be changed to verify the response content is correct.
  # TODO: Improve this test checking for a valid graph output
  test 'should get thesis file set metadata graph with n3 serialization' do
    sign_in_as_system_user
    get aip_v1_entity_file_set_url(
      entity: @entity,
      id: @public_thesis,
      file_set_id: @public_thesis.files.first.fileset_uuid
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    assert_equal true, graph.graph?
  end

  test 'should get thesis fixity metadata graph with n3 serialization' do
    sign_in_as_system_user

    url = aip_v1_entity_fileset_fixity_url(
      entity: @entity,
      id: @public_thesis,
      file_set_id: @public_thesis.files.first.fileset_uuid
    )

    graph = get_n3_graph(url)
    assert_response :success

    variables = {
      entity_id: @public_thesis.id,
      fileset_id: @public_thesis.files.first.fileset_uuid,
      checksum: @public_thesis.files.first.blob.checksum,
      byte_size: @public_thesis.files.first.blob.byte_size
    }
    rendered_graph = load_n3_graph(file_fixture('n3/theses/fixity.n3'), variables)

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

  # TODO: Improve this test checking for a valid graph output
  test 'should get thesis original file metadata graph with n3 serialization' do
    sign_in_as_system_user

    url = aip_v1_entity_fileset_original_file_url(
      entity: @entity,
      id: @public_thesis,
      file_set_id: @public_thesis.files.first.fileset_uuid
    )

    graph = get_n3_graph(url)
    assert_response :success

    variables = {
      entity_id: @public_thesis.id,
      fileset_id: @public_thesis.files.first.fileset_uuid,
      checksum: @public_thesis.files.first.blob.checksum,
      byte_size: @public_thesis.files.first.blob.byte_size,
      filename: @public_thesis.files.first.blob.filename
    }
    rendered_graph = load_n3_graph(file_fixture('n3/theses/original_file.n3'), variables)

    assert_equal true, rendered_graph.isomorphic_with?(graph)
  end

end
