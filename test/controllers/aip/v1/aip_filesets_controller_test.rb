require 'test_helper'
require 'fileutils'

class Aip::V1::FilesetsControllerTest < ActionDispatch::IntegrationTest

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

  # Basic tests checking if response has n3 serialization.
  # This should be changed to verify the response content is correct.

  test 'should get file set metadata graph with n3 serialization' do
    sign_in_as @admin_user
    get aip_v1_model_file_set_url(
      model: @model,
      id: @public_model,
      file_set_id: @public_model.files[0].fileset_uuid
    )
    assert_response :success

    graph = generate_graph_from_n3(response.body)
    assert_equal true, graph.graph?
  end

  test 'should get fixity metadata graph with n3 serialization' do
    sign_in_as @admin_user

    url = aip_v1_model_fileset_fixity_url(
      model: @model,
      id: @public_model,
      file_set_id: @public_model.files[0].fileset_uuid
    )

    graph = get_n3_graph(url)
    assert_response :success
    assert_equal true, graph.graph?
  end

  test 'should get original file metadata graph with n3 serialization' do
    sign_in_as @admin_user

    url = aip_v1_model_fileset_original_file_url(
      model: @model,
      id: @public_model,
      file_set_id: @public_model.files[0].fileset_uuid
    )

    graph = get_n3_graph(url)
    assert_response :success
    assert_equal true, graph.graph?
  end

  test 'should download image/jpeg file' do
    file_path = Rails.root.join('tmp/storage/DO/OM')
    FileUtils.mkpath file_path
    FileUtils.cp file_fixture('blobs/DOOMik3dEPshhSpd4mkh9xpB'), file_path

    sign_in_as @admin_user

    url = aip_v1_model_fileset_download_url(
      model: @model,
      id: @public_model,
      file_set_id: @public_model.files[0].fileset_uuid
    )
    get url

    assert_response :success
    assert_equal 'attachment; filename="image-sample.jpeg"',
                 @response.headers['Content-Disposition']
    assert_equal 'image/jpeg', @response.content_type
  end

  test 'should download text/plain file' do
    sign_in_as @admin_user
    file_path = Rails.root.join('tmp/storage/DO/OM')
    FileUtils.mkpath Rails.root.join(file_path)
    FileUtils.cp file_fixture('blobs/DOOMCMkcmwRQMPxngnHKHYJ7'), file_path

    url = aip_v1_model_fileset_download_url(
      model: @model,
      id: @public_model,
      file_set_id: @public_model.files[1].fileset_uuid
    )
    get url

    assert_response :success
    assert_equal 'text/plain', @response.content_type
    assert_equal 'attachment; filename="lorem.txt"',
                 @response.headers['Content-Disposition']
    assert_includes @response.body, 'Lorem ipsum dolor'
  end

end
