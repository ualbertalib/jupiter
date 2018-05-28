require 'test_helper'

class FileSetsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    @community = locked_ldp_fixture(Community, :fancy).unlock_and_fetch_ldp_object(&:save!)
    @collection = locked_ldp_fixture(Collection, :fancy).unlock_and_fetch_ldp_object(&:save!)
    @filename = 'text-sample.txt'
    @item = locked_ldp_fixture(Item, :fancy).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(@community.id, @collection.id)
      File.open(file_fixture(@filename), 'r') do |file|
        uo.add_files([file])
      end
      uo.save!
    end
    @file_set_id = @item.file_sets.first.id
  end

  test 'get view' do
    get "/items/#{@item.id}/view/#{@file_set_id}/#{@filename}"
    assert_response :success

    assert_equal response.headers['Content-Disposition'], 'inline; filename="text-sample.txt"'
    assert_equal response.headers['Content-Type'], 'text/plain'
    assert_equal response.headers['Accept-Ranges'], 'bytes'
    assert_equal response.headers['Content-Length'], '42'
  end

  test 'get view, wrong filename' do
    get "/items/#{@item.id}/view/#{@file_set_id}/wow.jpeg"
    assert_response :not_found
  end

  test 'get view, wrong file_set' do
    get "/items/#{@item.id}/view/90210/#{@filename}"
    assert_response :not_found
  end

  test 'get view, wrong item id' do
    get "/items/90210/view/#{@file_set_id}/#{@filename}"
    assert_response :not_found
  end

  test 'get download' do
    get "/items/#{@item.id}/download/#{@file_set_id}"
    assert_response :success

    assert_equal response.headers['Content-Disposition'], 'attachment; filename="text-sample.txt"'
    assert_equal response.headers['Content-Type'], 'application/octet-stream'
  end

  test 'head works on download' do
    head "/items/#{@item.id}/download/#{@file_set_id}"
    assert_response :success

    assert_equal response.headers['Accept-Ranges'], 'bytes'
    assert_equal response.headers['Content-Length'], '42'
  end

  test 'gets a range for download' do
    get "/items/#{@item.id}/download/#{@file_set_id}", headers: { 'HTTP_RANGE' => 'bytes=3-15' }
    assert_equal response.headers['Content-Range'], 'bytes 3-15/42'
    assert_equal response.headers['Content-Length'], '13'
    assert_equal response.body, 'ice, brief fi'
  end

end
