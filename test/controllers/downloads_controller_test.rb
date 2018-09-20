require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    community = locked_ldp_fixture(Community, :nice).unlock_and_fetch_ldp_object(&:save!)
    collection = locked_ldp_fixture(Collection, :nice).unlock_and_fetch_ldp_object(&:save!)
    item = locked_ldp_fixture(Item, :fancy).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    Sidekiq::Testing.inline! do
      File.open(file_fixture('text-sample.txt'), 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    @file = item.files.first
  end

  test 'file should be viewable with proper headings' do
    get file_view_item_url(id: @file.record.owner.id,
                           file_set_id: @file.fileset_uuid,
                           file_name: @file.filename)

    assert_response :success
    assert_equal @response.content_type, 'text/plain'
    assert_equal @response.headers['Content-Disposition'], 'inline'
    assert_includes @response.body, 'A nice, brief file, with some great text.'
  end

  test 'file should be downloadable with proper headings' do
    get file_download_item_url(id: @file.record.owner.id,
                               file_set_id: @file.fileset_uuid)

    assert_response :success
    assert_equal @response.content_type, 'text/plain'
    assert_equal @response.headers['Content-Disposition'], 'attachment'
    assert_includes @response.body, 'A nice, brief file, with some great text.'
  end

end
