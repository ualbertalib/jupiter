require 'test_helper'

class Digitization::BatchMetadataIngestTest < ActiveSupport::TestCase

  setup do
    @batch_ingest = digitization_batch_metadata_ingests(:digitization_batch_ingest_with_two_items)
  end

  test 'valid batch ingest' do
    @batch_ingest.csvfile.attach(io: File.open(file_fixture('digitization_metadata_graph.csv')),
                                 filename: 'folkfest.csv')
    assert_predicate @batch_ingest, :valid?
  end

  test 'invalid without csvfile' do
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:csvfile].first)
  end

  test 'invalid without title' do
    @batch_ingest.title = nil
    assert_not @batch_ingest.valid?
    assert_equal("can't be blank", @batch_ingest.errors[:title].first)
  end

  test 'invalid without expected headings' do
    csv_content = Tempfile.new('test_invalid_without_expected_headings')
    csv_content.puts 'Date,Amount,Account,User,'
    csv_content.puts '2014-12-01,12.01,abcxyz,user1'

    @batch_ingest.csvfile.attach(io: csv_content,
                                 filename: 'folkfest.csv', content_type: 'text/csv')

    assert_not @batch_ingest.valid?

    errors = ['Entity not found for row 1 of spreadsheet', 'Property not found for row 1 of spreadsheet',
              'Value not found for row 1 of spreadsheet', 'Graph contains no local identifiers']
    assert_equal(errors, @batch_ingest.errors[:csvfile])
  end

  test 'invalid without any local identifiers' do
    csv_content = Tempfile.new('test_invalid_without_any_local_identifiers')
    csv_content.puts 'Entity,Property,Value,'
    csv_content.puts 'https://digitalcollections.library.ualberta.ca/resource/UUID,' \
                     'http://purl.org/dc/terms/title,Edmonton Folk Music Festival'

    @batch_ingest.csvfile.attach(io: csv_content,
                                 filename: 'folkfest.csv', content_type: 'text/csv')

    assert_not @batch_ingest.valid?
    assert_equal(['Graph contains no local identifiers'], @batch_ingest.errors[:csvfile])
  end

end
