require 'test_helper'
require Rails.root.join('test/support/aip_helper')

class Aip::V1::CollectionsControllerTest < ActionDispatch::IntegrationTest

  include AipHelper

  def setup
    @regular_user = users(:regular)
    @collection = collections(:fancy_collection)
  end

  test 'should be able to show a visible collection to system user' do
    sign_in_as_system_user
    get aip_v1_collection_url(
      id: @collection
    )
    assert_response :success
  end

  test 'should not be able to show a visible collection to user' do
    sign_in_as @regular_user
    get aip_v1_collection_url(
      id: @collection
    )
    assert_response :redirect
  end

  # TODO: Add test checking graph shape after we finalize its format

end
