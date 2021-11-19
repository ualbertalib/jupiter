require 'test_helper'

class Digitization::BatchArtifactSetupIngestTest < ActiveSupport::TestCase

  setup do
    @batch_ingest = digitization_batch_artifact_setup_ingests(:digitization_batch_ingest_with_one_item)
  end

  test 'valid batch ingest' do
    @batch_ingest.csvfile.attach(io: File.open(file_fixture('digitization_artifacts_manifest.csv')),
                                 filename: 'artifacts_manifest.csv')
    assert @batch_ingest.valid?
  end

  test 'invalid without csvfile' do
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:csvfile].first)
  end

  test 'invalid without expected headings' do
    csv_content = Tempfile.new('test_invalid_without_expected_headings')
    csv_content.puts 'Date,Amount,Account,User,'
    csv_content.puts '2014-12-01,12.01,abcxyz,user1'

    @batch_ingest.csvfile.attach(io: csv_content,
                                 filename: 'artifacts_manifest.csv', content_type: 'text/csv')

    assert_not @batch_ingest.valid?

    errors = ['Local Identifier (Code) not found for row 1 of spreadsheet', 'Noid not found for row 1 of spreadsheet']
    assert_equal(errors, @batch_ingest.errors[:csvfile])
  end

end
