require 'test_helper'

class BatchIngestionJobTest < ActiveJob::TestCase

  test 'batch ingestion with no matching files' do
    batch_ingest = batch_ingests(:batch_ingest_with_one_file)

    assert_no_difference('Item.count') do
      VCR.use_cassette('google_fetch_spreadsheet',
                       record: :none,
                       erb: {
                         collection_id: collections(:collection_fantasy).id,
                         community_id: communities(:community_books).id
                       }) do
        BatchIngestionJob.perform_now(batch_ingest)
      end

      batch_ingest.reload
      assert_predicate(batch_ingest, :completed?)
      assert_equal(0, batch_ingest.items.count)
    end
  end

  test 'batch ingestion job captures exceptions and updates batch ingest model' do
    batch_ingest = batch_ingests(:batch_ingest_with_one_file)

    def batch_ingest.processing!
      raise StandardError, 'An exception was raised!'
    end

    BatchIngest.stub :find, batch_ingest do
      assert_no_difference('Item.count') do
        assert_raises StandardError do
          BatchIngestionJob.perform_now(batch_ingest)
        end
      end

      batch_ingest.reload
      assert_predicate(batch_ingest, :failed?)
      assert_equal('An exception was raised!', batch_ingest.error_message)
    end
  end

  test 'successful batch ingestion' do
    batch_ingest = batch_ingests(:batch_ingest_with_three_files)

    assert_difference('Item.count', +2) do
      VCR.use_cassette('google_fetch_spreadsheet',
                       record: :none,
                       erb: {
                         collection_id: collections(:collection_fantasy).id,
                         community_id: communities(:community_books).id
                       }) do
        VCR.use_cassette('google_fetch_file',
                         record: :none,
                         allow_playback_repeats: true) do
          BatchIngestionJob.perform_now(batch_ingest)
        end
      end

      batch_ingest.reload
      assert_predicate(batch_ingest, :completed?)
      assert_equal(2, batch_ingest.items.count)
    end
  end

  test 'batch ingestion with multiple files in one row' do
    batch_ingest = batch_ingests(:batch_ingest_with_multiple_files_in_one_item)

    # The VCR cassettes for this test where created using Net::HTTP calls
    # seperatedly which are not used in the test any more as we are using the
    # created cassettes.

    # The file cassette were created with code that looks like which downloded 6
    # files in a single cassette

    # VCR.use_cassette('google_fetch_multiple_text_files_in_utf8_encoding') do
    #   uris = [
    #     URI('https://www.googleapis.com/drive/v3/files/FILE1ID?alt=media'),
    #     URI('https://www.googleapis.com/drive/v3/files/FILE2ID?alt=media'),
    #     URI('https://www.googleapis.com/drive/v3/files/FILE3ID?alt=media'),
    #     URI('https://www.googleapis.com/drive/v3/files/FILE4ID?alt=media'),
    #     URI('https://www.googleapis.com/drive/v3/files/FILE5ID?alt=media'),
    #     URI('https://www.googleapis.com/drive/v3/files/FILE6ID?alt=media')
    #   ]
    #   uris.each do |uri|
    #     Net::HTTP.get(uri)
    #   end
    # end

    # The VCR cassette was created in a similar way. However, the yaml serializer
    # was adding the spreadsheet in binary format. The file required to be edited
    # so we could modify it with ERB so the configuration for VCR in the
    # test_helper.rb file was changed with

    # cassette.response.body.force_encoding('UTF-8')

    # VCR.use_cassette('google_fetch_spreadsheet_multiple_text_files_in_one_row') do
    #   uri = URI("https://sheets.googleapis.com/v4/spreadsheets/SPREADSHEETID/'Data'!A:W?key=test-gooogle-developer-key")
    #   Net::HTTP.get(uri)
    # end

    assert_difference('Item.count', +3) do
      assert_difference('ActiveStorage::Blob.count', +6) do
        VCR.use_cassette('google_fetch_spreadsheet_multiple_text_files_in_one_row',
                         record: :none,
                         erb: {
                           collection_id: collections(:collection_fantasy).id,
                           community_id: communities(:community_books).id
                         }) do
          VCR.use_cassette('google_fetch_multiple_text_files_in_utf8_encoding',
                           record: :none,
                           allow_playback_repeats: true) do
                             BatchIngestionJob.perform_now(batch_ingest)
                           end
        end
      end
    end

    batch_ingest.reload
    assert_predicate(batch_ingest, :completed?)
    assert_equal(3, batch_ingest.items.count)
    # Check items have their multiple files attached. Order is not guaranteed so
    # we need to look for the newly ingested items by name as defined in vcr
    # cassette google_fetch_spreadsheet_multiple_text_files_in_one_row.yml
    assert_equal(2, Item.find_by(title: 'Test Resource Title 1').files.count)
    assert_equal(3, Item.find_by(title: 'Test Resource Title 2').files.count)
    assert_equal(1, Item.find_by(title: 'Test Resource Title 3').files.count)
  end

end
