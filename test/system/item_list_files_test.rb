require 'application_system_test_case'

class ItemListFilesTest < ApplicationSystemTestCase

  test 'files are alphabetically sorted when depositing an item' do
    admin = users(:user_admin)
    item = items(:item_old_license)
    item.save

    # Make sure the item already has a file attached to it
    File.open(file_fixture('pdf-sample.pdf'), 'r') do |file|
      item.add_and_ingest_files([file])
    end

    login_user admin

    visit item_path item

    click_on I18n.t('edit')

    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')

    attach_file_in_dropzone(file_fixture('image-sample.jpeg'))
    attach_file_in_dropzone(file_fixture('Other-text-sample.txt'))
    attach_file_in_dropzone(file_fixture('1234-text-sample.txt'))

    assert_selector '#js-files-list ul li', count: 4
    assert_selector '#js-files-list ul li:nth-child(1) h5', text: '1234-text-sample.txt'
    assert_selector '#js-files-list ul li:nth-child(2) h5', text: 'image-sample.jpeg'
    assert_selector '#js-files-list ul li:nth-child(3) h5', text: 'Other-text-sample.txt'
    assert_selector '#js-files-list ul li:nth-child(4) h5', text: 'pdf-sample.pdf'

    click_on I18n.t('items.draft.save_and_continue'), wait: 10

    assert_selector :xpath, "(.//li[contains(@class, 'item-filename')])", count: 4
    # We are using regex in these assertions since the elements on the intreface
    # include a badge with text showing the file size
    assert_selector :xpath, "(.//li[contains(@class, 'item-filename')])[1]", text: /1234-text-sample.txt/
    assert_selector :xpath, "(.//li[contains(@class, 'item-filename')])[2]", text: /image-sample.jpeg/
    assert_selector :xpath, "(.//li[contains(@class, 'item-filename')])[3]", text: /Other-text-sample.txt/
    assert_selector :xpath, "(.//li[contains(@class, 'item-filename')])[4]", text: /pdf-sample.pdf/

    click_on I18n.t('items.draft.save_and_deposit_edits')

    assert_selector '.item-files > div', count: 4
    assert_selector '.item-files > div:nth-child(1) .item-filename', text: '1234-text-sample.txt'
    assert_selector '.item-files > div:nth-child(2) .item-filename', text: 'image-sample.jpeg'
    assert_selector '.item-files > div:nth-child(3) .item-filename', text: 'Other-text-sample.txt'
    assert_selector '.item-files > div:nth-child(4) .item-filename', text: 'pdf-sample.pdf'

    logout_user
  end

end
