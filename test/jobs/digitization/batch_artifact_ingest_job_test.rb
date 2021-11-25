require 'test_helper'

class Digitization::BatchArtifactIngestJobTest < ActiveJob::TestCase

  test 'successful artifacts ingestion' do
    batch_artifact_ingest = digitization_batch_artifact_ingests(:digitization_batch_ingest_with_one_item)
    batch_artifact_ingest.csvfile.attach(io: File.open(file_fixture('digitization_artifacts_manifest.csv')),
                                         filename: 'artifacts_manifest.csv')

    book = digitization_books(:folk_fest)
    book.fulltext.destroy
    book.reload

    assert_not(book.swift_noid.present?)
    assert_not(book.files.attached?)
    assert_not(book.fulltext.present?)

    Digitization::BatchArtifactIngestJob.perform_now(batch_artifact_ingest, book.peel_id, book.part_number,
                                                     'dig439b')

    book.reload
    assert(batch_artifact_ingest.completed?)
    assert_equal('dig439b', book.swift_noid)
    assert_equal('peel', book.swift_container)
    assert_equal('OpenStack/Swift', book.preservation_storage)
    assert(book.files.attached?)
    assert(book.thumbnail_file.present?)
    assert(book.fulltext.present?)
    assert_nothing_raised do
      ActiveStorage::Blob.find(book.files.first.blob_id).download
    end
  end

  test 'failure because book does not exist' do
    batch_artifact_ingest = digitization_batch_artifact_ingests(:digitization_batch_ingest_with_one_item)
    batch_artifact_ingest.csvfile.attach(io: File.open(file_fixture('digitization_artifacts_manifest.csv')),
                                         filename: 'artifacts_manifest.csv')

    assert_raises ActiveRecord::RecordNotFound do
      Digitization::BatchArtifactIngestJob.perform_now(batch_artifact_ingest, 1, 1, 'dig439b')
    end
    assert(batch_artifact_ingest.failed?)
  end

  test 'captures exceptions and updates batch ingest model' do
    batch_artifact_ingest = digitization_batch_artifact_ingests(:digitization_batch_ingest_with_one_item)
    batch_artifact_ingest.csvfile.attach(io: File.open(file_fixture('digitization_artifacts_manifest.csv')),
                                         filename: 'artifacts_manifest.csv')
    book = digitization_books(:folk_fest)

    def batch_artifact_ingest.archival_information_package_path
      raise StandardError, 'Testing! Error has happened!'
    end

    assert_raises StandardError do
      Digitization::BatchArtifactIngestJob.perform_now(batch_artifact_ingest, book.peel_id, book.part_number,
                                                       'dig439b')
    end

    assert(batch_artifact_ingest.failed?)
    assert_equal('Testing! Error has happened!', batch_artifact_ingest.error_message)
  end

end
