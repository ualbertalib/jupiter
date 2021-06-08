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

end
