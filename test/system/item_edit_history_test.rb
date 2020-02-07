require 'application_system_test_case'

class ItemEditHistoryTest < ApplicationSystemTestCase

  test 'can view thesis edit history' do
    with_versioning do
      admin = users(:admin)
      thesis = thesis(:edit_thesis_history)
      thesis.save

      # Need to add file to thesis to be able to go through editing wizard.
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        thesis.add_and_ingest_files([file])
      end
      login_user admin

      visit item_path thesis
      # TODO: not sure why the login didn't persist.
      click_on I18n.t('application.navbar.links.login')

      click_on I18n.t('edit')
      fill_in 'draft_thesis_title', with: 'New title'

      click_on I18n.t('admin.theses.draft.save_and_continue')

      choose 'draft_thesis_visibility_embargo'
      select('2025', from: 'draft_thesis_embargo_end_date_1i')
      select('August', from: 'draft_thesis_embargo_end_date_2i')
      select('19', from: 'draft_thesis_embargo_end_date_3i')

      click_on I18n.t('admin.theses.draft.save_and_continue')
      click_on I18n.t('admin.theses.draft.save_and_continue')
      click_on I18n.t('admin.theses.draft.save_and_deposit_edits')
      assert_text I18n.t('admin.theses.draft.successful_deposit')

      click_on I18n.t('edit_history')
      assert_selector 'dt', text: 'Edited by'
      assert_selector 'dd', text: 'Administrator - administrator@example.com'
      assert_selector 'dt', text: 'Title'
      assert_selector 'dd', text: 'OldNew title'
      assert_selector 'dt', text: 'Visibility'
      assert_selector 'dd', text: 'PublicEmbargo'
      assert_selector 'dt', text: 'Embargo End Date'
      assert_selector 'dd', text: 'August 18, 2025 18:00'
      assert_selector 'dt', text: 'Visibility After Embargo'
      assert_selector 'dd', text: 'Public'

      logout_user
    end
  end

  test 'can view item edit history' do
    with_versioning do
      admin = users(:admin)
      item = items(:edit_item_history)
      item.save

      # Need to add file to item to be able to go through editing wizard.
      File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
        item.add_and_ingest_files([file])
      end
      login_user admin

      visit item_path item
      # TODO: not sure why the login didn't persist.
      click_on I18n.t('application.navbar.links.login')
      click_on I18n.t('edit')

      fill_in 'draft_item_title', with: 'New title'
      select('Fancier Collection', from: 'draft_item_collection_id_')

      click_on I18n.t('items.draft.save_and_continue')
      click_on I18n.t('items.draft.save_and_continue')
      click_on I18n.t('items.draft.save_and_continue')
      click_on I18n.t('items.draft.save_and_deposit_edits')
      assert_text I18n.t('items.draft.successful_deposit')

      click_on I18n.t('edit_history')
      assert_selector 'dt', text: 'Edited by'
      assert_selector 'dd', text: 'Administrator - administrator@example.com'
      assert_selector 'dt', text: 'Title'
      assert_selector 'dd', text: 'OldNew title'
      assert_selector 'dt', text: 'Member Of Paths'
      assert_selector 'dd', text: 'Fancy Community/FancyFancier Collection'

      logout_user
    end
  end

end
