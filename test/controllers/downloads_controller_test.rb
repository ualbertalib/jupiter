require 'test_helper'

class DownloadsControllerTest < ActionDispatch::IntegrationTest

  def before_all
    super
    community = Community.create!(title: 'Nice community', owner_id: users(:admin).id)
    collection = Collection.create!(title: 'Nice collection', owner_id: users(:admin).id, community_id: community.id)
    item = Item.new(visibility: JupiterCore::VISIBILITY_PUBLIC,
                    owner_id: users(:admin).id, title: 'Fancy Item',
                    creators: ['Joe Blow'],
                    created: '1938-01-02',
                    languages: [CONTROLLED_VOCABULARIES[:language].english],
                    item_type: CONTROLLED_VOCABULARIES[:item_type].article,
                    publication_status:
                                               [CONTROLLED_VOCABULARIES[:publication_status].published],
                    license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
                    subject: ['Items']).tap do |uo|
      uo.add_to_path(community.id, collection.id)
      uo.save!
    end

    Sidekiq::Testing.inline! do
      File.open(file_fixture('text-sample.txt'), 'r') do |file|
        item.add_and_ingest_files([file])
      end
    end

    @file = item.files.first

    item_requiring_authentication = Item.new(
      title: 'item to download',
      owner_id: users(:admin).id,
      creators: ['Joe Blow'],
      created: '1972-08-08',
      languages: [CONTROLLED_VOCABULARIES[:language].english],
      license: CONTROLLED_VOCABULARIES[:license].attribution_4_0_international,
      visibility: JupiterCore::VISIBILITY_AUTHENTICATED,
      item_type: CONTROLLED_VOCABULARIES[:item_type].book,
      subject: ['Download']
    ).tap do |uo|
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
