require 'test_helper'

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @item = items(:fancy)
    @admin = users(:admin)
    sign_in_as @admin
  end

  test 'should get items index' do
    get admin_items_url
    assert_response :success
  end

  test 'should destroy item and its derivatives' do
    assert_difference(['Item.count'], -1) do
      delete admin_item_url(@item)
    end

    assert_redirected_to root_path
    assert_equal I18n.t('admin.items.destroy.deleted'), flash[:notice]
  end

end
