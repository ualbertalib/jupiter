require 'application_system_test_case'

class ThesisDescriptionOptionalTest < ApplicationSystemTestCase

  test 'cannot go through wizard step without description on thesis after 2009' do
    admin = users(:admin)
    thesis = thesis(:nice)
    login_user admin

    visit item_path thesis
    click_on I18n.t('edit')

    fill_in I18n.t('admin.theses.draft.describe_thesis.description'), with: ''

    click_on I18n.t('admin.theses.draft.save_and_continue')
    assert_text I18n.t('admin.theses.draft.please_fix_errors')

    logout_user
  end

  test 'can go through wizard step without description on thesis before 2009' do
    admin = users(:admin)
    thesis = thesis(:nice)
    login_user admin

    visit item_path thesis
    click_on I18n.t('edit')

    fill_in I18n.t('admin.theses.draft.describe_thesis.description'), with: ''
    select '2000', from: I18n.t('admin.theses.draft.describe_thesis.graduation_year')

    click_on I18n.t('admin.theses.draft.save_and_continue')
    assert_no_text I18n.t('admin.theses.draft.please_fix_errors')
    logout_user
  end

end
