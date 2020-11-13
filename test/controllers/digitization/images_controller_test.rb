require 'test_helper'

class Digitization::ImagesControllerTest < ActionDispatch::IntegrationTest

  setup do
    @digitization_image = digitization_images(:magee)
  end

  test 'should show digitization_image' do
    get image_url(@digitization_image)
    assert_response :success
  end

end
