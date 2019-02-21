require 'application_system_test_case'

class DepositThesisTest < ApplicationSystemTestCase

  def before_all
    super

    # Setup a community/collection pair for respective dropdowns
    @community = Community.new_locked_ldp_object(title: 'Theses', owner: 1).unlock_and_fetch_ldp_object(&:save!)
    @collection = Collection.new_locked_ldp_object(title: 'Theses Collection',
                                                   owner: 1,
                                                   restricted: true,
                                                   community_id: @community.id)
                            .unlock_and_fetch_ldp_object(&:save!)
  end

  test 'be able to deposit a new thesis into jupiter successfully' do
    admin = users(:admin)

    login_user(admin)

    click_link admin.name
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.items.index.header')
    click_link I18n.t('admin.items.index.deposit_thesis')

    skip 'This test continues to flap on CI for unknown reasons that should be investigated ASAP' if ENV['TRAVIS']

    # 1. Describe Thesis Form

    assert_selector 'h1', text: I18n.t('admin.theses.draft.header')
    assert_selector 'h2', text: I18n.t('admin.theses.draft.describe_thesis.header')

    fill_in I18n.t('admin.theses.draft.describe_thesis.title'),
            # Need to narrow down by placeholder since capybara can't differentiate from title and alternate title labels
            placeholder: I18n.t('admin.theses.draft.describe_thesis.title_placeholder'),
            with: 'A Dance with Dragons'

    fill_in I18n.t('admin.theses.draft.describe_thesis.creator'),
            with: 'Jane Doe'

    select '2018', from: I18n.t('admin.theses.draft.describe_thesis.graduation_year')
    select '06 (Spring)', from: I18n.t('admin.theses.draft.describe_thesis.graduation_term')

    fill_in I18n.t('admin.theses.draft.describe_thesis.description'),
            with: 'A Dance with Dragons Description Goes Here!!!'

    select @community.title, from: 'draft_thesis[community_id][]'
    select @collection.title, from: 'draft_thesis[collection_id][]'

    click_on I18n.t('admin.theses.draft.save_and_continue')

    # 2. Choose License and Visibility Form

    assert_selector 'h2', text: I18n.t('admin.theses.draft.choose_license_and_visibility.header')

    fill_in 'draft_thesis_rights',
            with: 'Open for everyone!'

    choose I18n.t('admin.theses.draft.choose_license_and_visibility.visibility.embargo')
    select_date '2023/01/01', field_id: 'draft_thesis_embargo_end_date'

    click_on I18n.t('admin.theses.draft.save_and_continue')

    # 3. Upload File Form

    assert_selector 'h2', text: I18n.t('admin.theses.draft.upload_files.header')

    attach_file_in_dropzone(file_fixture('image-sample.jpeg'))
    has_css? '.j-thumbnail'

    click_on I18n.t('admin.theses.draft.save_and_continue'), wait: 5

    # 4. Review and Deposit Form

    assert_selector 'h2', text: I18n.t('admin.theses.draft.review_and_deposit_thesis.header')

    click_on I18n.t('admin.theses.draft.header')

    # Success! Deposit Successful

    assert_text I18n.t('admin.theses.draft.successful_deposit')
    assert_selector 'h1', text: Thesis.last.title

    # verify editing

    click_on I18n.t('edit')
    assert_selector 'h1', text: I18n.t('admin.theses.draft.header_edit')
    fill_in I18n.t('admin.theses.draft.describe_thesis.title'),
            currently_with: 'A Dance with Dragons',
            with: 'The Winds of Winter'
    click_on I18n.t('admin.theses.draft.save_and_continue')

    click_on I18n.t('admin.theses.draft.save_and_continue')
    click_on I18n.t('admin.theses.draft.save_and_continue')
    click_on I18n.t('admin.theses.draft.save_and_deposit_edits')
    assert_text I18n.t('admin.theses.draft.successful_deposit')
    assert_selector 'h1', text: 'The Winds of Winter'
  end

  test 'should populate community and collection when coming from a restricted collection page' do
    admin = users(:admin)

    login_user(admin)

    # Navigate to restricted collection page
    click_link I18n.t('application.navbar.links.communities')
    click_link @community.title
    click_link @collection.title

    # Click deposit button
    click_link I18n.t('collections.show.deposit_thesis')

    assert has_select?('draft_thesis[community_id][]', selected: @community.title)
    assert has_select?('draft_thesis[collection_id][]', selected: @collection.title)
  end

  # Helper methods for javascript fields (dropzone)
  # (could be moved and made as generic helpers if these are needed elsewhere)
  private

  def attach_file_in_dropzone(file_path)
    # Attach the file to the hidden input selector
    attach_file(nil, file_path, class: 'dz-hidden-input', visible: false)
  end

  def select_date(date, field_id:)
    date = Date.parse(date)

    select date.year.to_s, from: "#{field_id}_1i"
    select I18n.l(date, format: '%B'), from: "#{field_id}_2i"
    select date.day.to_s, from: "#{field_id}_3i"
  end

end
