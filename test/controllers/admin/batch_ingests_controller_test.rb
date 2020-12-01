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
    assert_response :success
  end

  test 'should create batch_ingest' do
    assert_difference('BatchIngest.count') do
      post admin_batch_ingests_url, params: { batch_ingest: { title: 'Random Batch Name'} }
    end

    assert_redirected_to admin_batch_ingest_url(BatchIngest.last)
  end

  test 'should show batch_ingest' do
    get admin_batch_ingest_url(@batch_ingest)
    assert_response :success
  end
end
