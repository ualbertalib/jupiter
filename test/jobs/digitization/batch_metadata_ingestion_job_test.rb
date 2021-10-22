require 'test_helper'

class Digitization::BatchMetadataIngestionJobTest < ActiveJob::TestCase

  test 'batch ingestion job captures exceptions and updates batch ingest model' do
    batch_ingest = digitization_batch_metadata_ingests(:digitization_batch_ingest_with_two_items)

    def batch_ingest.processing!
      raise StandardError, 'Testing! Error has happened!'
    end

    assert_raises StandardError do
      assert_no_difference('::Digitization::Book.count') do
        Digitization::BatchMetadataIngestionJob.perform_now(batch_ingest)
      end
    end

    assert(batch_ingest.failed?)
    assert_equal('Testing! Error has happened!', batch_ingest.error_message)
  end

  test 'successful batch ingestion' do
    batch_ingest = digitization_batch_metadata_ingests(:digitization_batch_ingest_with_two_items)
    batch_ingest.csvfile.attach(io: File.open(file_fixture('digitization_metadata_graph.csv')),
                                filename: 'folkfest.csv')

    assert_difference('::Digitization::Book.count', +2) do
      Digitization::BatchMetadataIngestionJob.perform_now(batch_ingest)
    end

    batch_ingest.reload
    assert(batch_ingest.completed?)
    assert_equal(2, batch_ingest.books.count)
  end

end