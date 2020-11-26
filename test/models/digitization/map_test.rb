require 'test_helper'

class Digitization::MapTest < ActiveSupport::TestCase

  setup do
    @map = digitization_maps(:map)
  end

  test 'valid Peel map' do
    assert @map.valid?
  end

  test 'unique Peel map' do
    map = Digitization::Map.create(peel_map_id: 'M000230')
    assert_not map.valid?
    assert_equal('has already been taken', map.errors[:peel_map_id].first)
  end

end
