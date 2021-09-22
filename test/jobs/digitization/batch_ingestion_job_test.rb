require 'test_helper'

class Digitization::BatchIngestionJobTest < ActiveJob::TestCase

  test 'batch ingestion job captures exceptions and updates batch ingest model' do
    batch_ingest = digitization_batch_ingests(:digitization_batch_ingest_with_two_items)

    def batch_ingest.processing!
      raise StandardError, 'Testing! Error has happened!'
    end

    assert_raises StandardError do
      assert_no_difference('::Digitization::Book.count') do
        Digitization::BatchIngestionJob.perform_now(batch_ingest)
      end
    end

    assert(batch_ingest.failed?)
    assert_equal('Testing! Error has happened!', batch_ingest.error_message)
  end

  test 'successful batch ingestion' do
    batch_ingest = digitization_batch_ingests(:digitization_batch_ingest_with_two_items)
    batch_ingest.metadata_csv.attach(io: File.open(file_fixture('digitization_metadata_graph.csv')),
                                     filename: 'folkfest.csv')
    batch_ingest.manifest_csv.attach(io: File.open(file_fixture('digitization_manifest.csv')),
                                     filename: 'manifest.csv')

    assert_difference('::Digitization::Book.count', +2) do
      Digitization::BatchIngestionJob.perform_now(batch_ingest)
    end

    batch_ingest.reload
    assert(batch_ingest.completed?)
    assert_equal(2, batch_ingest.books.count)
    assert(batch_ingest.books.first.valid?)
    assert(batch_ingest.books.first.files.attached?)
  end

end
