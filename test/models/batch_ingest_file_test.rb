require 'test_helper'

class BatchIngestFileTest < ActiveSupport::TestCase

  setup do
    @batch_ingest_file = batch_ingest_files(:batch_ingest_file_one)
  end

  test 'valid batch ingest file' do
    assert @batch_ingest_file.valid?
  end

  test 'invalid without google file id' do
    @batch_ingest_file.google_file_id = nil
    assert_not @batch_ingest_file.valid?
    assert_equal("can't be blank", @batch_ingest_file.errors[:google_file_id].first)
  end

  test 'invalid without google file name' do
    @batch_ingest_file.google_file_name = nil
    assert_not @batch_ingest_file.valid?
    assert_equal("can't be blank", @batch_ingest_file.errors[:google_file_name].first)
  end

  test 'invalid without batch ingest' do
    @batch_ingest_file.batch_ingest = nil
    assert_not @batch_ingest_file.valid?
    assert_equal('must exist', @batch_ingest_file.errors[:batch_ingest].first)
  end

end
