require 'application_system_test_case'

class DepositItemTest < ApplicationSystemTestCase

  def before_all
    super

    # Setup a community/collection pair for respective dropdowns
    @community = Community.new_locked_ldp_object(title: 'Books', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Fantasy Books',
                                                   owner: 1,
                                                   community_id: @community.id)
                            .unlock_and_fetch_ldp_object(&:save!)
  end

  test 'be able to deposit a new item into jupiter successfully' do
    user = users(:regular)

    login_user(user)

    click_link I18n.t('application.navbar.links.new_item')

    # 1. Describe Item Form

    assert_selector 'h1', text: I18n.t('items.draft.header')
    assert_selector 'h2', text: I18n.t('items.draft.describe_item.header')

    fill_in I18n.t('items.draft.describe_item.title'),
            # Need to narrow down by placeholder since capybara can't differentiate from title and alternate title labels
            placeholder: I18n.t('items.draft.describe_item.title_placeholder'),
            with: 'A Dance with Dragons'

    select 'Book', from: I18n.t('items.draft.describe_item.type_id')
    selectize_option '.draft_item_languages', with: 'English'

    selectize_set_text '.draft_item_creators', with: 'George R. R. Martin'

    selectize_set_text '.draft_item_subjects', with: 'A Song of Ice and Fire'
    selectize_set_text '.draft_item_subjects', with: 'Fantasy'

    select_date '2011/07/12', field_id: 'draft_item_date_created'

    fill_in I18n.t('items.draft.describe_item.description'), with: 'A Dance with Dragons Description Goes Here!!!'

    select @community.title, from: 'draft_item[community_id][]'
    select @collection.title, from: 'draft_item[collection_id][]'

    click_on I18n.t('items.draft.save_and_continue')

    # 2. Choose License and Visibility Form

    assert_selector 'h2', text: I18n.t('items.draft.choose_license_and_visibility.header')

    # Open accordion
    click_on I18n.t('items.draft.choose_license_and_visibility.license.link_to_another_license')

    choose I18n.t('items.draft.choose_license_and_visibility.license.license_text_html')
    fill_in 'draft_item_license_text_area', with: 'License Text Goes Here!!!'

    choose I18n.t('items.draft.choose_license_and_visibility.visibility.embargo')
    select_date '2023/01/01', field_id: 'draft_item_embargo_end_date'

    click_on I18n.t('items.draft.save_and_continue')

    # 3. Upload File Form

    assert_selector 'h2', text: I18n.t('items.draft.upload_files.header')

    attach_file_in_dropzone(file_fixture('image-sample.jpeg'))

    click_on I18n.t('items.draft.save_and_continue')

    # 4. Review and Deposit Form

    assert_selector 'h2', text: I18n.t('items.draft.review_and_deposit_item.header')

    click_on I18n.t('items.draft.header')

    # Success! Deposit Successful

    assert_text I18n.t('items.draft.successful_deposit')
    assert_selector 'h1', text: Item.last.title

    # verify editing

    click_on I18n.t('edit')
    assert_selector 'h1', text: I18n.t('items.draft.header_edit')
    fill_in I18n.t('items.draft.describe_item.title'),
            currently_with: 'A Dance with Dragons',
            with: 'The Winds of Winter'
    click_on I18n.t('items.draft.save_and_continue')

    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_continue')
    click_on I18n.t('items.draft.save_and_deposit_edits')
    assert_text I18n.t('items.draft.successful_deposit')
    assert_selector 'h1', text: 'The Winds of Winter'
  end

  test 'should populate community and collection when coming from collection page' do
    user = users(:regular)

    login_user(user)

    # Navigate to collection page
    click_link I18n.t('application.navbar.links.communities')
    click_link 'Books'
    click_link 'Fantasy Books'

    # Click deposit button
    click_link I18n.t('collections.show.deposit_item')

    assert has_select?('draft_item[community_id][]', selected: 'Books')
    assert has_select?('draft_item[collection_id][]', selected: 'Fantasy Books')
  end

  # Helper methods for javascript fields (selectize/dropzone) and date select
  # (could be moved and made as generic helpers if these are needed elsewhere)
  private

  def selectize_set_text(key, with:)
    within key do
      first('.selectize-input input').set(with)
      first('.selectize-dropdown-content .create').click
    end
  end

  def selectize_option(key, with:)
    within key do
      first('.selectize-input input').click
      find('.option', text: with).click
    end
  end

  def select_date(date, field_id:)
    date = Date.parse(date)

    select date.year.to_s, from: "#{field_id}_1i"
    select I18n.l(date, format: '%B'), from: "#{field_id}_2i"
    select date.day.to_s, from: "#{field_id}_3i"
  end

  def attach_file_in_dropzone(file_path)
    # Attach the file to the hidden input selector
    attach_file(nil, file_path, class: 'dz-hidden-input', visible: false)
  end

end
