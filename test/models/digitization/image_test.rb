require 'test_helper'

class Digitization::ImageTest < ActiveSupport::TestCase

  setup do
    @image = digitization_images(:magee)
  end

  test 'valid Peel image' do
    assert @image.valid?
  end

  test 'unique Peel image' do
    image = Digitization::Image.create(peel_image_id: 'MGNGBG0001')
    assert_not image.valid?
    assert_equal('has already been taken', image.errors[:peel_image_id].first)
    image.destroy
  end

end
