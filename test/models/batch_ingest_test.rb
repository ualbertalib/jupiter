require 'test_helper'

class BatchIngestTest < ActiveSupport::TestCase

  setup do
    @batch_ingest = batch_ingests(:batch_ingest_with_one_file)
  end

  test 'valid batch ingest' do
    assert_predicate @batch_ingest, :valid?
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

  test 'invalid when files exceed maximum length' do
    51.times do |i|
      @batch_ingest.batch_ingest_files.new(google_file_id: "file id #{i}", google_file_name: "file name #{i}")
    end

    assert_not @batch_ingest.valid?
    assert_equal(
      'too many files added (maximum is 50 files). If you need more files, try submitting multiple batch ingests',
      @batch_ingest.errors[:batch_ingest_files].first
    )
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
      VCR.use_cassette('google_fetch_spreadsheet_multiple_duplicate_files_in_one_row',
                       record: :none,
                       erb: { community_id: 'BADID',
                              collection_id: 'BADID' }) do
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
        assert_equal("Invalid metadata on row 1 of spreadsheet: Unknown visibility key: Public",
                     batch_ingest.errors[:google_spreadsheet_id].third)
        # rubocop:disable Layout/LineLength
        assert_equal("File(s) 'file_1.txt, file_2.txt, file_3.txt' from row 1 of spreadsheet are not listed in the file list below",
                     batch_ingest.errors[:google_spreadsheet_id].fourth)
        assert_equal("File 'file_1.txt' is repeated in rows 1, 2 of the spreadsheet but should only appear in a single row",
                     batch_ingest.errors[:google_spreadsheet_id][10])
        # rubocop:enable Layout/LineLength

      end
    end
  end

end
