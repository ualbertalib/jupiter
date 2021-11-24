require 'test_helper'

class Digitization::BatchArtifactsSetupIngestionJobTest < ActiveJob::TestCase

  test 'successful batch setup' do
    batch_artifact_ingest = digitization_batch_artifact_ingests(:digitization_batch_ingest_with_one_item)
    batch_artifact_ingest.csvfile.attach(io: File.open(file_fixture('digitization_artifacts_manifest.csv')),
                                         filename: 'artifacts_manifest.csv')

    perform_enqueued_jobs(only: Digitization::BatchArtifactsSetupIngestionJob) do
      Digitization::BatchArtifactsSetupIngestionJob.perform_later(batch_artifact_ingest)
    end

    assert_performed_jobs 1
    assert_enqueued_jobs 1, only: Digitization::BatchArtifactIngestJob
  end

  test 'captures exceptions and updates batch ingest model' do
    batch_artifact_ingest = digitization_batch_artifact_ingests(:digitization_batch_ingest_with_one_item)
    def batch_artifact_ingest.csvfile
      raise StandardError, 'Testing! Error has happened!'
    end
    assert_raises StandardError do
      Digitization::BatchArtifactsSetupIngestionJob.perform_now(batch_artifact_ingest)
    end

    assert(batch_artifact_ingest.failed?)
    assert_equal('Testing! Error has happened!', batch_artifact_ingest.error_message)
  end

end
