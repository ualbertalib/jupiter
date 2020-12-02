require 'test_helper'

class BatchIngestTest < ActiveSupport::TestCase

  def setup
    @batch_ingest = batch_ingests(:one)
  end

  test 'valid batch_ingest' do
    assert @batch_ingest.valid?
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
