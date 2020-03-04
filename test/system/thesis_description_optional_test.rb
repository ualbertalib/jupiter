require 'application_system_test_case'

class ThesisDescriptionOptionalTest < ApplicationSystemTestCase

  test 'cannot go through wizard step without description on thesis after 1990' do
    admin = users(:admin)
    thesis = thesis(:nice)
    thesis.save
    login_user admin

    visit item_path thesis
    click_on I18n.t('edit')

    click_on I18n.t('admin.theses.draft.save_and_continue')
    assert_text I18n.t('admin.theses.draft.please_fix_errors')

    logout_user
  end

  test 'can go through wizard step without description on thesis before 1990' do
    admin = users(:admin)
    thesis = thesis(:legacy)
    thesis.save
    login_user admin

    visit item_path thesis
    click_on I18n.t('edit')

    click_on I18n.t('admin.theses.draft.save_and_continue')
    assert_no_text I18n.t('admin.theses.draft.please_fix_errors')
    logout_user
  end

end
