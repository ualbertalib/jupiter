require 'application_system_test_case'

class EditItemOldLicenseTest < ApplicationSystemTestCase

  test 'can edit and save an item with an old license' do
    skip 'ignore'
    admin = users(:admin)
    item = items(:old_license)
    item.save

    # Need to add file to item to be able to go through editing wizard.
    File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
      item.add_and_ingest_files([file])
    end
    login_user admin

    visit item_path item
    assert_text I18n.t('controlled_vocabularies.old_license.attribution_3_0_international')

    click_on I18n.t('edit')

    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')

    assert_text I18n.t('controlled_vocabularies.old_license.attribution_3_0_international')
    logout_user
  end

end
