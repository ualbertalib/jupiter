require 'test_helper'

class Admin::BatchIngestsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @batch_ingest = batch_ingests(:one)
    sign_in_as(users(:admin))
  end

  test 'should get index' do
    get admin_batch_ingests_url
    assert_response :success
  end

  test 'should get new' do
    get new_admin_batch_ingest_url
    assert_response :redirect
    assert_redirected_to google_callback_admin_batch_ingests_url
  end

  test 'should get google_callback' do
    get google_callback_admin_batch_ingests_url

    assert_response :redirect
    assert_redirected_to %r(\Ahttps://accounts.google.com/o/oauth2/auth)
  end

  test 'should get new with credentials' do
    VCR.use_cassette('google_fetch_access_token', record: :none) do
      get google_callback_admin_batch_ingests_url, params: {
        code: 'CODE12345'
      }
    end

    assert_response :redirect
    assert_redirected_to new_admin_batch_ingest_url

    follow_redirect!
    assert_response :success
  end

  test 'should create batch_ingest' do
    assert_difference('BatchIngest.count') do
      post admin_batch_ingests_url, params: {
        batch_ingest: {
          title: 'Random Batch Name',
          file_names: ['feature_image.jpg'],
          file_ids: ['RANDOMSTRING'],
          spreadsheet_name: 'google_spreadsheet',
          spreadsheet_id: 'RANDOMSTRING'
        }
      }
    end

    assert_redirected_to admin_batch_ingest_url(BatchIngest.last)
  end

  test 'should show batch_ingest' do
    get admin_batch_ingest_url(@batch_ingest)
    assert_response :success
  end

end
