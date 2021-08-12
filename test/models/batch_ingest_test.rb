require 'test_helper'

class BatchIngestTest < ActiveSupport::TestCase

  setup do
    @batch_ingest = batch_ingests(:batch_ingest_with_one_file)
  end

  test 'valid batch ingest' do
    assert @batch_ingest.valid?
  end

  test 'invalid without access token' do
    @batch_ingest.access_token = nil
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:access_token].first)
  end

  test 'invalid without files' do
    @batch_ingest.batch_ingest_files = []
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:batch_ingest_files].first)
  end

  test 'invalid without google spreadsheet id' do
    @batch_ingest.google_spreadsheet_id = nil
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:google_spreadsheet_id].first)
  end

  test 'invalid without google spreadsheet name' do
    @batch_ingest.google_spreadsheet_name = nil
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:google_spreadsheet_name].first)
  end

  test 'invalid without title' do
    @batch_ingest.title = nil
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:title].first)
  end

  test 'invalid if title taken already' do
    @batch_ingest.title = 'Conference Batch'
    assert_not @batch_ingest.valid?
    assert_equal('has already been taken', @batch_ingest.errors[:title].first)
  end

  test 'invalid without user' do
    @batch_ingest.user = nil
    assert_not @batch_ingest.valid?
    assert_equal('must exist', @batch_ingest.errors[:user].first)
  end

  test 'invalid unless spreadsheet has required data' do
    VCR.use_cassette('google_fetch_access_token', record: :none) do
      VCR.use_cassette('google_fetch_spreadsheet', record: :none,
                                                   erb: { community_id: 'BADID',
                                                          collection_id: 'BADID',
                                                          owner_id: 'BADID' }) do
        batch_ingest = BatchIngest.new(
          title: @batch_ingest.title,
          user_id: @batch_ingest.user_id,
          batch_ingest_files: @batch_ingest.batch_ingest_files,
          google_spreadsheet_id: @batch_ingest.google_spreadsheet_id,
          google_spreadsheet_name: @batch_ingest.google_spreadsheet_name,
          access_token: @batch_ingest.access_token
        )

        assert_not batch_ingest.valid?
        assert_equal('community_id does not exist in ERA for row 1 of spreadsheet',
                     batch_ingest.errors[:google_spreadsheet_id].first)
        assert_equal('collection_id does not exist in ERA for row 1 of spreadsheet',
                     batch_ingest.errors[:google_spreadsheet_id].second)
        assert_equal('owner_id does not exist in ERA for row 1 of spreadsheet',
                     batch_ingest.errors[:google_spreadsheet_id].third)
      end
    end
  end

end
