require 'application_system_test_case'

class AdminBatchIngestsTest < ApplicationSystemTestCase

  setup do
    @batch_ingest = batch_ingests(:one)
    @admin = users(:admin)
    login_user(@admin)
  end

  teardown do
    logout_user
  end

  test 'visiting the index' do
    visit admin_batch_ingests_url
    assert_selector 'h1', text: 'Batch Ingests'
  end

  # TODO:
  # test 'creating a Batch ingest' do
  #   visit admin_batch_ingests_url
  #   click_on 'New Batch Ingest'

  #   click_on 'Create Batch ingest'

  #   assert_text 'Batch ingest was successfully created'
  #   click_on 'Back'
  # end

end
