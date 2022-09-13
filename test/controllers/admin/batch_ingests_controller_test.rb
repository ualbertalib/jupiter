require 'test_helper'

class Admin::BatchIngestsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @batch_ingest = batch_ingests(:batch_ingest_with_one_file)
    sign_in_as(users(:user_admin))
  end

  test 'should get index' do
    get admin_batch_ingests_url
    assert_response :success
  end

  test 'should redirect to google session callback without valid google credentials' do
    get new_admin_batch_ingest_url
    assert_response :redirect
    assert_redirected_to new_admin_google_session_url
  end

  test 'should get new when having valid google credentials' do
    VCR.use_cassette('google_fetch_access_token', record: :none) do
      get new_admin_google_session_url, params: {
        code: 'RANDOMCODE'
      }
    end

    assert_response :redirect
    assert_redirected_to new_admin_batch_ingest_url

    follow_redirect!
    assert_response :success
  end

  test 'should create batch_ingest' do
    assert_no_enqueued_jobs only: BatchIngestionJob

    VCR.use_cassette('google_fetch_access_token', record: :none) do
      get new_admin_google_session_url, params: {
        code: 'RANDOMCODE'
      }
    end

    VCR.use_cassette('google_fetch_spreadsheet',
                     record: :none,
                     erb: {
                       collection_id: collections(:collection_fantasy).id,
                       community_id: communities(:community_books).id
                     }) do
      assert_difference('BatchIngest.count') do
        assert_difference('BatchIngestFile.count', +2) do
          post admin_batch_ingests_url, params: {
            batch_ingest: {
              title: 'Random Batch Name',
              batch_ingest_files_attributes: [
                { google_file_id: 'randomfileid', google_file_name: 'conference_logo.png' },
                { google_file_id: 'randomfileid', google_file_name: 'conference.pdf' }
              ],
              google_spreadsheet_name: 'Test - ERA Batch Ingest Template',
              google_spreadsheet_id: 'RANDOMSPREADSHEETID'
            }
          }
        end
      end
    end
    assert_enqueued_jobs 1, only: BatchIngestionJob
    assert_redirected_to admin_batch_ingest_url(BatchIngest.last)

    clear_enqueued_jobs
  end

  test 'should show batch_ingest' do
    get admin_batch_ingest_url(@batch_ingest)
    assert_response :success
  end

end
