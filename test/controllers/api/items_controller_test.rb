require 'test_helper'

class Aip::V1::ItemsControllerTest < ActionDispatch::IntegrationTest

  # Transactional tests were creating a problem where a collection defined as a
  # fixture would only be found sometimes (a race condition?)
  self.use_transactional_tests = false

  def setup
    @regular_user = users(:regular)
    @public_item = items(:public_item)
    @private_item = items(:private_item)
  end

  test 'should be able to show a visible item' do
    sign_in_as @regular_user
    get aip_v1_item_url(@public_item)
    assert_response :success
  end

  test 'should not be able to show a private item' do
    sign_in_as @regular_user
    get aip_v1_item_url(@private_item)
    assert_response :redirect
  end

end
