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

    item_requiring_authentication = Item.new_locked_ldp_object(
      title: 'item to download',
      owner: 1,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
      item_type: CONTROLLED_VOCABULARIES[:item_type].book,
      subject: ['Download']
    ).unlock_and_fetch_ldp_object do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    Sidekiq::Testing.inline! do
      File.open(file_fixture('text-sample.txt'), 'r') do |file|
        item_requiring_authentication.add_and_ingest_files([file])
      end
    end

    @file_requiring_authentication = item_requiring_authentication.files.first
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

  test 'authentication required file shouldnt be viewable if not authenticated' do
    get file_view_item_url(id: @file_requiring_authentication.record.owner.id,
                           file_set_id: @file_requiring_authentication.fileset_uuid,
                           file_name: @file_requiring_authentication.filename)

    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized_try_logging_in'), flash[:alert]
  end

  test 'authentication required file should be downloadable if not authenticated' do
    get file_download_item_url(id: @file_requiring_authentication.record.owner.id,
                               file_set_id: @file_requiring_authentication.fileset_uuid)

    assert_redirected_to root_url
    assert_equal I18n.t('authorization.user_not_authorized_try_logging_in'), flash[:alert]
  end

end
