require 'application_system_test_case'

class ThumbnailResettingTest < ApplicationSystemTestCase

  test "thumbnail choice doesn't reset between saves" do
    admin = users(:admin)
    item = items(:admin)

    File.open(file_fixture('image-sample.jpeg'), 'r') do |file1|
      File.open(file_fixture('image-sample2.jpeg'), 'r') do |file2|
        item.add_and_ingest_files([file1, file2])
      end
    end

    login_user admin
    visit item_path item

    click_on I18n.t('edit')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    click_on I18n.t('edit')
    # Thumbnail set as first attachment by default.
    first_thumbnail_id = DraftItem.drafts.find_by(uuid: item.id).thumbnail_id
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on 'Set as Thumbnail'
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    click_on I18n.t('edit')
    # Thumbnail set as second attachment.
    second_thumbnail_id = DraftItem.drafts.find_by(uuid: item.id).thumbnail_id
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    click_on I18n.t('edit')
    # Thumbnail still set as second attachment.
    third_thumbnail_id = DraftItem.drafts.find_by(uuid: item.id).thumbnail_id
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    # Assert that statements in above comments are true.
    assert first_thumbnail_id != second_thumbnail_id
    assert first_thumbnail_id != third_thumbnail_id
    assert second_thumbnail_id == third_thumbnail_id

    logout_user
  end

end
