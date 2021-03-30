require 'test_helper'

class DoiResetTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:admin)
    @user = users(:regular)

    @item = items(:fancy)
  end

  test 'reset button displays as needed' do
    skip('This is flapping on CI')
    sign_in_as @admin
    get item_url(@item)

    # time travel to when that object was created.
    travel_to(@item.created_at) do
      # Reset DOI doesn't show up because the item was just created.
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0
    end

    travel_to(@item.created_at + 2.minutes) do
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 1

      # Doesn't show button when logged out or not an admin.
      get logout_url
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0

      sign_in_as @user
      get item_url(@item)
      assert_select '.admin-sidebar .btn', text: I18n.t('items.admin_sidebar.reset_doi'), count: 0
    end
  end

end
