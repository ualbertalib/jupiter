require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  setup do
    item = items(:fancy)

    File.open(file_fixture('text-sample.txt'), 'r') do |file|
      item.add_and_ingest_files([file])
    end

    @file = item.reload.files.first

    item_requiring_authentication = items(:authenticated_item)

    File.open(file_fixture('text-sample.txt'), 'r') do |file|
      item_requiring_authentication.add_and_ingest_files([file])
    end

    @file_requiring_authentication = item_requiring_authentication.reload.files.first
  end

  test 'file should be viewable with proper headings' do
    get file_view_item_url(id: @file.record.id,
                           file_set_id: @file.fileset_uuid,
                           file_name: @file.filename)

    assert_response :success
    assert_equal @response.media_type, 'text/plain'
    assert_equal @response.headers['Content-Disposition'], 'inline'
    assert_includes @response.body, 'A nice, brief file, with some great text.'
  end

  test 'file should be downloadable with proper headings' do
    get file_download_item_url(id: @file.record.id,
                               file_set_id: @file.fileset_uuid)

    assert_response :success
    assert_equal @response.media_type, 'text/plain'
    assert_equal @response.headers['Content-Disposition'], 'attachment'
    assert_includes @response.body, 'A nice, brief file, with some great text.'
  end

  test 'authentication required file shouldnt be viewable if not authenticated' do
    get file_view_item_url(id: @file_requiring_authentication.record.id,
                           file_set_id: @file_requiring_authentication.fileset_uuid,
                           file_name: @file_requiring_authentication.filename)

    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized_try_logging_in'), flash[:alert]
  end

  test 'authentication required file should be downloadable if not authenticated' do
    get file_download_item_url(id: @file_requiring_authentication.record.id,
                               file_set_id: @file_requiring_authentication.fileset_uuid)

    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized_try_logging_in'), flash[:alert]
  end

end
