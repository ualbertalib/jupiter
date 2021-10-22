require 'application_system_test_case'

class AdminBatchIngestsTest < ApplicationSystemTestCase

  setup do
    @batch_ingest = batch_ingests(:batch_ingest_with_one_file)
    @admin = users(:user_admin)
    login_user(@admin)
  end

  teardown do
    logout_user
  end

  test 'visiting the index' do
    visit admin_batch_ingests_url
    assert_selector 'h1', text: I18n.t('admin.batch_ingests.index.header')
  end

  test 'visting show page of a batch ingest' do
    visit admin_batch_ingest_url(@batch_ingest)
    assert_selector 'h1', text: @batch_ingest.title
  end

end
