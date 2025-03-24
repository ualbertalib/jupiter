require 'test_helper'

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @item = items(:item_fancy)
    @admin = users(:user_admin)
    sign_in_as @admin

    File.open(file_fixture('text-sample.txt'), 'r') do |file|
      @item.add_and_ingest_files([file])
    end
  end

  test 'should get items index' do
    get admin_items_url

    assert_response :success
  end

  test 'should destroy item and its derivatives' do
    assert_difference(['Item.count', 'ActiveStorage::Attachment.count'], -1) do
      delete admin_item_url(@item)
    end

    assert_redirected_to root_path
    assert_equal I18n.t('admin.items.destroy.deleted'), flash[:notice]
  end

  test 'shouldnt destroy read_only item' do
    @item.read_only = true
    @item.save!

    delete admin_item_url(@item)

    assert_redirected_to item_path @item
    assert_equal I18n.t('items.edit.read_only'), flash[:alert]

    @item.read_only = false
    @item.save!
  end

  test 'reset DOI should queue job' do
    assert_no_enqueued_jobs only: DOIRemoveJob
    Rails.application.secrets.doi_minting_enabled = true

    patch reset_doi_admin_item_url(@item)

    assert_response :redirect
    assert_redirected_to root_url
    assert_enqueued_jobs 1, only: DOICreateJob

    clear_enqueued_jobs
    Rails.application.secrets.doi_minting_enabled = false
  end

end
