require 'application_system_test_case'

class DepositThesisTest < ApplicationSystemTestCase

  test 'be able to deposit and edit a thesis successfully' do
    admin = users(:user_admin)

    login_user(admin)

    click_link admin.name
    click_link I18n.t('application.navbar.links.admin')
    click_link I18n.t('admin.items.index.header')
    click_link I18n.t('admin.items.index.deposit_thesis')

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

    select communities(:community_thesis).title, from: 'draft_thesis[community_id][]'
    select collections(:collection_thesis).title, from: 'draft_thesis[collection_id][]'

    click_on I18n.t('admin.theses.draft.save_and_continue')

    # 2. Choose License and Visibility Form

    assert_selector 'h2', text: I18n.t('admin.theses.draft.choose_license_and_visibility.header')

    fill_in 'draft_thesis_rights',
            with: 'Open for everyone!'

    choose I18n.t('admin.theses.draft.choose_license_and_visibility.visibility.embargo')

    # set Embargo's "Will be open access on" field to first day of current year
    select Date.current.year.to_s, from: 'draft_thesis_embargo_end_date_1i'
    select 'January', from: 'draft_thesis_embargo_end_date_2i'
    select '1', from: 'draft_thesis_embargo_end_date_3i'

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
    assert_predicate Thesis.find_by(title: 'A Dance with Dragons'), :present?
    assert_selector 'h1', text: 'A Dance with Dragons'

    # Check to make sure there isn't any embargo_history
    item_id = current_url.split('/').last
    _, item_results, _, _ = JupiterCore::Search.perform_solr_query(q: item_id, fq: "id:#{item_id}", rows: 1)

    assert_nil item_results.first['embargo_history_ssim']

    # verify editing

    click_on I18n.t('edit')

    assert_selector 'h1', text: I18n.t('admin.theses.draft.header_edit')

    # edit title
    fill_in I18n.t('admin.theses.draft.describe_thesis.title'),
            currently_with: 'A Dance with Dragons',
            with: 'The Winds of Winter'
    click_on I18n.t('admin.theses.draft.save_and_continue')

    # edit visibility
    choose I18n.t('admin.theses.draft.choose_license_and_visibility.visibility.open_access')
    click_on I18n.t('admin.theses.draft.save_and_continue')
    click_on I18n.t('admin.theses.draft.save_and_continue')
    click_on I18n.t('admin.theses.draft.save_and_deposit_edits')

    assert_text I18n.t('admin.theses.draft.successful_deposit')
    assert_selector 'h1', text: 'The Winds of Winter'

    # go back to editing to ensure visibility stuck
    click_on I18n.t('edit')

    assert_selector 'h1', text: I18n.t('admin.theses.draft.header_edit')
    click_on I18n.t('admin.theses.draft.save_and_continue')

    assert_selector '#draft_thesis_visibility_open_access:checked'

    # Ensure embargo_history is now present
    _, item_results, _, _ = JupiterCore::Search.perform_solr_query(q: item_id, fq: "id:#{item_id}", rows: 1)

    assert_not_nil item_results.first['embargo_history_ssim']
    logout_user
  end

  test 'should populate community and collection when coming from a restricted collection page' do
    community = communities(:community_thesis)
    collection = collections(:collection_thesis)

    admin = users(:user_admin)

    login_user(admin)

    # Navigate to restricted collection page
    click_link I18n.t('application.navbar.links.communities')
    click_link community.title
    click_link collection.title

    # Click deposit button
    click_link I18n.t('collections.show.deposit_thesis')

    assert has_select?('draft_thesis[community_id][]', selected: community.title)
    assert has_select?('draft_thesis[collection_id][]', selected: collection.title)

    logout_user
  end

end
