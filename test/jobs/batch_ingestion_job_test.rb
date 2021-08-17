require 'test_helper'

class BatchIngestionJobTest < ActiveJob::TestCase

  test 'batch ingestion with no matching files' do
    batch_ingest = batch_ingests(:batch_ingest_with_one_file)

    assert_no_difference('Item.count') do
      VCR.use_cassette('google_fetch_spreadsheet',
                       record: :none,
                       erb: {
                         collection_id: collections(:collection_fantasy).id,
                         community_id: communities(:community_books).id,
                         owner_id: users(:user_admin).id
                       }) do
        BatchIngestionJob.perform_now(batch_ingest.id)
      end

      batch_ingest.reload
      assert(batch_ingest.completed?)
      assert_equal(0, batch_ingest.items.count)
    end
  end

  test 'batch ingestion job captures exceptions and updates batch ingest model' do
    batch_ingest = batch_ingests(:batch_ingest_with_one_file)

    def batch_ingest.processing!
      raise StandardError, 'An exception was raised!'
    end

    BatchIngest.stub :find, batch_ingest do
      assert_raises StandardError do
        assert_no_difference('Item.count') do
          BatchIngestionJob.perform_now(batch_ingest.id)
        end
      end

      batch_ingest.reload
      assert(batch_ingest.failed?)
      assert_equal('An exception was raised!', batch_ingest.error_message)
    end
  end

  test 'successful batch ingestion' do
    batch_ingest = batch_ingests(:batch_ingest_with_two_files)

    assert_difference('Item.count', +2) do
      VCR.use_cassette('google_fetch_spreadsheet',
                       record: :none,
                       erb: {
                         collection_id: collections(:collection_fantasy).id,
                         community_id: communities(:community_books).id,
                         owner_id: users(:user_admin).id
                       }) do
        VCR.use_cassette('google_fetch_file',
                         record: :none,
                         allow_playback_repeats: true) do
          BatchIngestionJob.perform_now(batch_ingest.id)
        end
      end

      batch_ingest.reload
      assert(batch_ingest.completed?)
      assert_equal(2, batch_ingest.items.count)
    end
  end

end
